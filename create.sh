#!/bin/bash

# Environment variables that need to be set
# TF_VAR_ec2_ssh_key
# TF_VAR_aws_profile
# TF_VAR_region
# TF_VAR_subnet_id_1
# TF_VAR_subnet_id_2
# TF_VAR_aws_vpc_id
# SERVER_PASSWORD
# TF_VAR_certificate_arn (when setting up secure server)


usage()
{
    echo "usage: create.sh [[-i image ] | [-s] | [-h]]"
}

code_server_img="codercom/code-server"
secure_domain=false

while [ "$1" != "" ]; do
    case $1 in
        -i | --image )          shift
                                code_server_img=$1
                                ;;
        -s | --secure )         secure_domain=true
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

# Display Docker image that will be used
printf "\n\nDocker image to use: $code_server_img \n\n"

# Determine if tfenv is installed
which tfenv
if [ $? == 0 ]
then
    printf 'tfenv is installed, setting version of terraform \n'
    tfenv use 0.12.21
else
    printf 'tfenv is not installed, ensure you are using terraform version 0.12.21 \n'
fi

if [ -e ".env" ]
then
    printf "Reading environment variables \n"
    . ./.env
else
    printf "Environment (.env) file not found \n"
fi

# Check if terraform init has already run
if [ ! -d ".terraform" ]; then
    printf "Running terraform init \n"
    terraform init
fi

printf "\nSecure domain value: %s \n" "$secure_domain"
if [ $secure_domain == false ] && [ ! -e "./server.crt" ] && [ ! -e "./server.key" ]
then
    export TF_VAR_protocol=HTTP
    export TF_VAR_certificate_arn=''
    printf 'For non-secure domain, creating empty cert and key files. \n'
    touch server.crt
    touch server.key
elif [ $secure_domain == false ]
then
    export TF_VAR_protocol=HTTP
    export TF_VAR_certificate_arn=''
    printf 'Non-secure domain \n'
elif [ $secure_domain == true ]
then
    export TF_VAR_protocol=HTTPS
    if [ TF_VAR_certificate_arn == "" ]
    then
        printf 'A certificate ARN from AWS Certificate Manager must be defined. Set TF_VAR_certificate_arn \n'
    fi
fi

printf "Retrieving Amazon Linux 2 AMI ID for region %s \n" "$TF_VAR_REGION"
export TF_VAR_ami_id_amazon_linux=$(aws ec2 describe-images --filters "Name=owner-alias,Values=amazon" "Name=architecture,Values=x86_64" "Name=description,Values='Amazon Linux 2 AMI 2.0.20191024.3 x86_64 HVM gp2'" --profile $TF_VAR_aws_profile --region $TF_VAR_region | jq -r '.Images[].ImageId')
printf "\nAmazon Linux 2 AMI ID is: $TF_VAR_ami_id_amazon_linux \n\n"

printf "Running terraform apply \n\n"
terraform apply
if [ $? -ne 0 ]
then
   printf "Terraform Failed \n"
   exit 1
fi

printf "Obtaining public IP address... \n"
public_ip=$(terraform output -json | jq -r '.server_output.value')

printf "Obtaining DNS address of load balancer... \n"
public_dns=$(terraform output -json | jq -r '.load_balancer_output.value' )

printf "\nPull Docker Image... \n"
ssh -i ~/.ssh/$TF_VAR_ec2_ssh_key.pem ec2-user@$public_ip \
docker image pull $code_server_img

printf "\nChecking for existing service... \n"
count=$(ssh -i ~/.ssh/$TF_VAR_ec2_ssh_key.pem ec2-user@$public_ip docker container ls | wc -l)
if [ $count -eq 1 ]
then
    printf "\nStarting service... \n\n"

    if [ $secure_domain == true ]
    then
        printf "Running secure container... \n"
        ssh -i ~/.ssh/$TF_VAR_ec2_ssh_key.pem ec2-user@$public_ip \
        docker run -it -d -p 8080:8080 \
            -v "/mnt/projects:/home/coder/project" \
            -e PASSWORD=$SERVER_PASSWORD \
            $code_server_img \
            --cert server.crt --cert-key server.key
    else
        printf "Running non-secure container... \n"
        ssh -i ~/.ssh/$TF_VAR_ec2_ssh_key.pem ec2-user@$public_ip \
        docker run -it -d -p 8080:8080 \
            -v "/mnt/projects:/home/coder/project" \
            -e PASSWORD=$SERVER_PASSWORD \
            $code_server_img
    fi
else
    printf "\nService already running \n\n"
fi

printf "\nPublic IP: $public_ip \n"
printf "Server password: $SERVER_PASSWORD \n"

if [ $secure_domain == false ]
then
    printf "Full URL: http://$public_dns:8080 \n"
elif [ $secure_domain == true ]
then
    printf "For access, make sure to add CNAME entry in your DNS zone to: $public_dns \n"
    printf "The server will be available on port 8080 \n"
fi
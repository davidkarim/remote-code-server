#!/bin/bash

# Environment variables that need to be set
# TF_VAR_ec2_ssh_key
# TF_VAR_aws_profile
# TF_VAR_region
# TF_VAR_subnet_id_1
# TF_VAR_subnet_id_2
# TF_VAR_aws_vpc_id
# SERVER_PASSWORD

code_server_img="codercom/code-server"

echo "Retrieving Amazon Linux 2 AMI ID for region $TF_VAR_region"
export TF_VAR_ami_id_amazon_linux=$(aws ec2 describe-images --filters "Name=owner-alias,Values=amazon" "Name=architecture,Values=x86_64" "Name=description,Values='Amazon Linux 2 AMI 2.0.20191024.3 x86_64 HVM gp2'" --profile $TF_VAR_aws_profile --region $TF_VAR_region | jq -r '.Images[].ImageId')
echo "Amazon Linux 2 AMI ID is: $TF_VAR_ami_id_amazon_linux"

echo "Running terraform apply"
terraform apply
if [ $? -ne 0 ]
then
   echo "Terraform Failed"
   exit 1
fi

echo "Obtaining public IP address"
public_ip=$(terraform output -json | jq -r '.server_output.value')

echo "Obtaining DNS address of load balancer"
public_dns=$(terraform output -json | jq -r '.load_balancer_output.value' )

echo "Pull Docker Image"
ssh -i ~/.ssh/$TF_VAR_ec2_ssh_key.pem ec2-user@$public_ip \
docker image pull $code_server_img

echo "Checking for existing service..."
count=$(ssh -i ~/.ssh/$TF_VAR_ec2_ssh_key.pem ec2-user@$public_ip docker container ls | wc -l)
if [ $count -eq 1 ]
then
    echo "Starting service..."

    ssh -i ~/.ssh/$TF_VAR_ec2_ssh_key.pem ec2-user@$public_ip \
    docker run -it -d -p 8080:8080 \
        -v "/mnt/projects:/home/coder/project" \
        -e PASSWORD=$SERVER_PASSWORD \
        $code_server_img
else
    echo "Service already running"
fi

echo "Public IP: $public_ip"
echo "Public DNS: $public_dns"
echo "Server password: $SERVER_PASSWORD"
echo "Full URL: http://$public_dns:8080"
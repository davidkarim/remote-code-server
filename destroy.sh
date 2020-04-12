#!/bin/bash

# Determine if tfenv is installed
which tfenv
if [ $? == 0 ]
then
    printf 'tfenv is installed, setting version of terraform \n'
    tfenv use 0.11.13
else
    tf_version=$(terraform version | head -n 1 | awk -F 'v' '{print $2}')
    printf 'tfenv is not installed, your terraform version is %s \n' "$tf_version"
    printf 'q to quit. enter to continue. \n'
    read -n1 answer
    if [ "$answer" == 'q' ] || [ "$answer" == 'Q' ]; then
        exit 0
    fi
fi

if [ -e ".env" ]
then
    printf "Reading environment variables \n"
    . ./.env
else
    printf "Environment (.env) file not found, make sure env vars are set. \n"
fi

# Set ami_id_amazon_linux to any value
export TF_VAR_ami_id_amazon_linux="_"

printf "Running terraform destroy \n"
terraform destroy
printf "\nAll infrastructure has been removed from AWS \n\n"
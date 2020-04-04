#!/bin/bash

# Determine if tfenv is installed
which tfenv
if [ $? == 0 ]
then
    printf 'tfenv is installed, setting version of terraform \n'
    tfenv use 0.11.13
else
    printf 'tfenv is not installed, ensure you are using terraform version 0.11.13 \n'
fi

if [ -e ".env" ]
then
    printf "Reading environment variables \n"
    . ./.env
else
    printf "Environment (.env) file not found \n"
fi

# Set ami_id_amazon_linux to any value
export TF_VAR_ami_id_amazon_linux="_"

printf "Running terraform destroy \n"
terraform destroy
printf "\nAll infrastructure has been removed from AWS \n\n"
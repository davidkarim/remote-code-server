#!/bin/bash

export TF_VAR_aws_profile=$TF_VAR_aws_profile
export TF_VAR_region=$TF_VAR_region
export TF_VAR_ec2_ssh_key=$TF_VAR_ec2_ssh_key

echo "Running terraform destroy"
terraform destroy
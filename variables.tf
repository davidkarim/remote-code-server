# These variables are defined as TF_VAR_<var> environment variable in a .env file
variable "region" {}
variable "ami_id_amazon_linux" {}
variable "aws_profile" {}
variable "machine_type"
{
  default = "t2.micro"
}
variable "subnet_id_1" {}
variable "subnet_id_2" {}
variable "aws_vpc_id" {}
variable "ec2_ssh_key" {}
variable "certificate_arn" {}
variable "protocol" {}
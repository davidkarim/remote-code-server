# Remote-Code-Server

This repo contains the terraform scripts necessary to create a remote VS Code environment using [code-server](https://github.com/cdr/code-server) on your existing AWS account.

## Requirements

* [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
* [jq](https://stedolan.github.io/jq/download/)
* [Terraform 0.11.13](https://www.terraform.io/downloads.html)
* [tfenv](https://github.com/tfutils/tfenv) recommended to manage terraform versions

## Build Image

If you need a more customized environment, the Dockerfile has a custom Ruby image which is already available [here](https://hub.docker.com/repository/docker/davidkarim/code-server-ruby):

```bash
# Ruby environment
docker image build -t <docker-hub-account>/code-server-ruby .
docker image push <docker-hub-account>/code-server-ruby:latest
# Test and run environment locally
docker container run -it -p 127.0.0.1:8080:8080 -v "$PWD:/home/coder/project" <docker-hub-account>/code-server-ruby
```

Test and run original image locally:

```bash
# Starting server locally
docker container run -it -p 127.0.0.1:8080:8080 -v "$PWD:/home/coder/project" codercom/code-server
```

## Environment Variables

The following must be defined in a .env file:

| Variable name          | description                                                                    |
|------------------------|--------------------------------------------------------------------------------|
| TF_VAR_ec2_ssh_key     | Name of existing EC2 instance SSH key                                          |
| TF_VAR_aws_profile     | Name of AWS profile, typically located in ~/.aws/credentials                   |
| TF_VAR_region          | Region where to build infrastructure                                           |
| TF_VAR_subnet_id_1     | Public subnet for Application load balancer, EC2 will also be placed here.     |
| TF_VAR_subnet_id_2     | Secondary public subnet                                                        |
| TF_VAR_aws_vpc_id      | VPC identifier                                                                 |
| SERVER_PASSWORD        | Password that will be used for access to VS Code server. Use complex password. |
| TF_VAR_certificate_arn | AWS Certificate ARN. Needs to be set when using secure domains.                |

## Creating a Remote Server

To create the server, create a .env file with the environment variable values. Then run:

```bash
# Create infrastructure, use insecure domain
./create.sh
# Create infrastructure, use a secure domain
./create.sh --secure
# Create infrastructure, use a custom image, and secure domain
./create.sh -i davidkarim/code-server-ruby --secure
```

## Connecting to Remote Server

Use the endpoint provided to navigate to the server with your browser. The login password will also be provided and should be the same as defined in the .env file. When setting up a secure domain, a certificate needs to be provided and the name of that domain can be used to connect. Default port is 8080.

## Destroying Remote Server

To destroy the server:

```bash
# Destroy infrastructure
./destroy.sh
```

## To Do

* Option for updating Route53 domain.
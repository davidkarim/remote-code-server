# Remote-Code-Server

This repo contains the terraform scripts necessary to create a remote VS Code environment using [code-server](https://github.com/cdr/code-server) on your existing AWS account.

## Requirements

* [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
* [jq](https://stedolan.github.io/jq/download/)
* [Terraform 0.11.13](https://www.terraform.io/downloads.html)
* [tfenv](https://github.com/tfutils/tfenv) recommended to manage terraform versions

## Creating a Remote Server

To create the server, create a .env file with the environment variable values. Then run:

```bash
# If using tfenv, change to version 0.11.3 of terraform
tfenv use 0.11.13
# Create infrastructure
. ./.env && ./create.sh
```

## Connecting to Remote Server

Use the endpoint provided to navigate to the server with your browser. The login password will also be provided and should be the same as defined in the .env file.

## Destroying Remote Server

To destroy the server:

```bash
# Destroy infrastructure
./destroy.sh
```

## To Do

* Make ALB endpont work with SSL
* Instead of using the codercom/code-server image directly, build custom image.

See FAQ: https://github.com/cdr/code-server/blob/master/doc/FAQ.md
See here for recommended oauth from that FAQ: https://github.com/pusher/oauth2_proxy
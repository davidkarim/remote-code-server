# Hello World

## Creating a Remote Server

To create the server, create a .env file with the environment variable values. Then run:

```bash
. ./.env && ./create.sh
```

## Destroying Remote Server

To destroy the server:

```bash
./destroy.sh
```

## To Do

* Make ALB endpont work with SSL
* Instead of using the codercom/code-server image directly, build custom image.

See FAQ: https://github.com/cdr/code-server/blob/master/doc/FAQ.md
See here for recommended oauth from that FAQ: https://github.com/pusher/oauth2_proxy
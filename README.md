# Docker deploy

Docker deployment utilities for REDMIC infrastructure. You can use it to deploy your own services into your servers.

## Actions

* **deploy**: Perform a deployment of a service on a remote Docker environment. Contains 3 stages:

  * *prepare-deploy*: Copy resources to remote environment (*docker-compose* files, service configurations...), prepare environment variables and directories, etc.

  * *do-deploy*: Launch service on Docker environment. Both standard (using docker-compose) and Swarm modes are supported on remote Docker environment, but Swarm mode is recommended (even for a single-node clusters).

  * *check-deploy*: Once deployment is done, this stage wait a defined period of time for the service to being up and running (or stopped after run successfully). If service status remains stable after several checks, then it is considered successfully deployed.

* **create-nets**: Prepare remote environment creating Docker networks which are external to service (not created by service deployment itself).

* **relaunch**: Force a previously deployed service to update, relaunching it with the same service configuration. Available only for Swarm mode.

## Usage

For REDMIC, we use this image automatically from jobs defined in GitLabCI configuration, but you can run it directly:

```
$ docker run --rm --name docker-deploy \
	-e STACK=your-stack-name -e SSH_REMOTE=ssh-user@ssh-host -e DEPLOY_KEY="<your-private-key>" \
	redmic/docker-docker-deploy:latest \
	<action> <arg1> <arg2> ...
```

As you can see, there is configuration through environment variables and by script (<action>) parameters.

By environment variables, you can configure:
	* Behaviour of this image itself.
	* When action is *deploy* and using the `$ENV_PREFIX` in your variables, the remote environment (where you are deploying to) for service configuration.

By script parameters you can set:
	* When action is *deploy*, remote environment variables, in order to configure your service. These parameters overwrite remote environment variables, including those defined using the `$ENV_PREFIX`.
	* When action is *create-nets*, the name of the networks that are going to be created.

You may define these environment variables (**bold** are mandatory):

* **STACK**: Name of Docker stack (Swarm mode) or project (docker-compose mode) used to wrap deployed services.
* **SSH_REMOTE**: SSH user and host of remote machine where you are going to deploy.
* **DEPLOY_KEY**: Private key paired with a public key accepted by remote machine, used to authenticate.
* *SERVICE*: Name of service to relaunch. **Required** for relaunch action.
* *ENV_PREFIX*: Prefix used to identify variables to be defined in remote environment (without this prefix). Default `DD_`.
* *ENV_SPACE_REPLACEMENT*: Unique string used to replace spaces into variable values while handling them. Default `<dd-space>`.
* *COMPOSE_FILE*: Name of docker-compose file with deployment definition. Multiple files are supported, separated by colon (`:`). Default `docker-compose.yml`.
* *DEPLOY_PATH*: Path in remote host where deployment directory (containing temporary files) will be created. Default `~`.
* *DEPLOY_DIR_NAME*: Name of directory containing files needed for deployment. Default `deploy`.
* *DEFAULT_DEPLOY_FILES*: Files needed for deployment, if `${DEPLOY_DIR_NAME}` does not exist. Default `docker-compose*.yml .env`.
* *REGISTRY_URL*: Address of Docker registry where Docker images to deploy are stored. Leave it empty to use Docker Hub registry.
* *REGISTRY_USER*: Docker registry username of user with read permissions. **Required** for private registries.
* *REGISTRY_PASS*: Docker registry user password of user with read permissions. **Required** for private registries.
* *SERVICES_TO_CHECK*: Names of services to check after deployment, separated by space.
* *STATUS_CHECK_RETRIES*: Default `10`.
* *STATUS_CHECK_INTERVAL*: Default `20`.
* *STATUS_CHECK_DELAY*: Default `120`.
* *STATUS_CHECK_MIN_HITS*: Default `3`.
* *USE_IMAGE_DIGEST*: Update service image using digest data when relaunching. Default `0`.
* *GREP_BIN*: Default `grep`.

## Examples

### Deploy

```
# You must define a valid deploy configuration
$ ls -a deploy
.  ..  docker-compose.yml  .env

# Use a private key allowed in the remote host
$ export DEPLOY_KEY="
-----BEGIN RSA PRIVATE KEY-----
MIICXQIBAAKBgQDozua2ox1gweQ8/889/8ViH/9sI95+/6px1B+IKSJvmf1qLkD4
3xskMYsWuWmYhfXA8G1gYndTKvEPOB5rfzIT1/bL4jifNqL2cPnRvAvX5u9ddS2b
Qv+LceM37PcIxawYCpoLjoWrr9QMSZz6h62ciX4BbeH8SEXqNSHIrucEzwIDAQAB
AoGAev+9MycwwUsPTA8XLjlwzmv7ZeX5in2HTsZ0tlqNQAtKsQuo9hPh4hhu1N22
5Yd5FKuyDedYBc+9Nn4+zCqSiJltEXqpI1NQAwim1dBPos1940gBUPMMlXiwdMYV
MnozZaSo369P12DIK9r0iEwQlUi68koaH3zbTd6y28kqVtkCQQD1IGIo4mtaQ7tJ
SAlQI5ZZZPbF2NPFkAEK/8YkW1jC90vLRME9Qk4HnyKIjKCWq9Ij3VC+S8sJcbC2
uOWKN5JbAkEA8yKiH6S4v5B9zXUurCz2iZhD/tB1RYPD8YoRgkQ/cu7h4V9qtuII
Xk/ddxiuk+x3Fa4YLgUZEZ6I9YkrznQ5nQJATWevd4egLL3Mq2RjBHpoZMw8HNfO
b8l8etOv5xUtX0umFIcemlCQwVlgF0yI/Ws+jXK6p4zZjZ7oFZsnaNEJlwJBAMjG
lci5ttKCWFCc7wDBVIlFUwkOTXktGVbRpCnFf/vCJod8ytvhBfYTz5d0q11+DMy7
aj4+eXgiSYkxUBp5wcUCQQCZVEsjFFFnJCkZRyNqlCXrRsvpPNExg0BxnMcymEA8
sIhl4aG94WSKaj6MdST5Dzt/0qbyJXCThChJbahWToou
-----END RSA PRIVATE KEY-----
"

# Start service deployment:
#   to 'domain.net' remote host
#      identified as 'user'
#      authenticated through private key
#   into 'example' stack
#   with 'VARIABLE_1' and 'VARIABLE_2' available in environment
$ docker run --rm --name docker-deploy \
	-e STACK=example -e SSH_REMOTE=user@domain.net -e DEPLOY_KEY \
	-e DD_VARIABLE_1="variable 1" \
	-v $(pwd)/deploy:/deploy \
	redmic/docker-docker-deploy \
	deploy VARIABLE_2="variable 2"
```

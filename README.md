# Docker deploy

Docker deployment utilities for REDMIC infrastructure.
You can use it to deploy your own services, supporting **docker-compose** and **Docker Swarm** environments.

## Actions

* **deploy**: Perform a service deployment on a remote Docker environment. Contains 3 stages:

  * *prepare-deploy*: Copy resources to remote environment (*docker-compose* files, service configurations...), prepare environment variables and directories, etc.

  * *do-deploy*: Launch service on Docker environment. Both standard (using *docker-compose*) and *Swarm* modes are supported on remote Docker environment, but *Swarm* mode is recommended (even for single-node clusters).

  * *check-deploy*: Once deployment is done, this stage waits a defined time period for the service to being up and running (or stopped after run successfully). If service status remains stable after several checks, then it is considered successfully deployed.

* **create-nets**: Prepare remote environment creating Docker networks which are external to service definition (not created by service deployment itself, defined as *external* in compose files).

* **relaunch**: Force a previously deployed service to update, relaunching it with the same service configuration. Available only for *Swarm* mode.

## Usage

For REDMIC, we use this image into CI/CD configuration. Deploy jobs are defined into our [GitLab CI configuration](https://gitlab.com/redmic-project/gitlab-ci-templates), but you can run it directly using `docker run`:

```
$ docker run --rm --name docker-deploy \
	-e SSH_REMOTE=ssh-user@host -e DEPLOY_KEY="<your-private-key>" \
	-e STACK=your-stack-name \
	-v $(pwd)/docker-compose.yml:/docker-compose.yml \
	-v $(pwd)/.env:/.env \
	redmic/docker-docker-deploy:latest \
	<action> <arg1> <arg2> ...
```

As you can see, configuration is possible through environment variables and by script (<action>) parameters.

Using environment variables, you can configure:

* Behaviour of this image itself.
* Remote environment (where you are deploying to) for service configuration and service environment variables. Only when action is *deploy* and using the `ENV_PREFIX` prefix in your variable names.

Using script parameters you can set:

* When action is *deploy*, remote environment for service configuration and service environment variables. These parameters overwrite previous environment values, including those defined using the `ENV_PREFIX` prefix.
* When action is *create-nets*, the name of external networks to create.

## Configuration

### Docker deploy

You may define these environment variables (**bold** are mandatory):

* **DEPLOY_KEY**: Private key used to authenticate, paired with a public key accepted by remote host.
* **SSH_REMOTE**: SSH user and hostname (DNS or IP) of remote host where you are going to deploy.
* **STACK**: Name of Docker stack (*Swarm* mode) or project (*docker-compose* mode) used to wrap deployed services.


* *COMPOSE_FILE*: Name of service definition file. Multiple files are supported, separated by colon (`:`). Default `docker-compose.yml`.
* *DEFAULT_DEPLOY_FILES*: Files needed for deployment. Used only if `DEPLOY_DIR_NAME` directory does not exist. Default `docker-compose*.yml .env`.
* *DEPLOY_DIR_NAME*: Name of directory containing files needed for deployment. If directory exists, `DEFAULT_DEPLOY_FILES` is ignored and all content is copied to remote host. Default `deploy`.
* *DEPLOY_PATH*: Path in remote host where deployment directory (used to hold temporary files) will be created. Default `~`.
* *ENV_PREFIX*: Prefix used to identify variables to be defined in remote environment and service, available there without this prefix. Change this if default value collides with the beginning of your variable names. Default `DD_`.
* *ENV_SPACE_REPLACEMENT*: Unique string (change this if that is not true for you) used to replace spaces into variable values while handling them. Default `<dd-space>`.
* *FORCE_DOCKER_COMPOSE*: Use always standard (*docker-compose*) mode instead of Docker *Swarm*, even if it is available on remote Docker environment. Default `0`.
* *OMIT_CLEAN_DEPLOY*: Leave at remote host deployment resources after doing a successful deploy. Useful when using bind mounts or *docker-compose* secrets (pointing to static content in deployment resources). Default `0`.
* *GREP_BIN*: Path to *grep* binary in remote host. Default `grep`.
* *REGISTRY_PASS*: Docker registry password, corresponding to a user with read permissions. **Required** for private registry or repository.
* *REGISTRY_URL*: Docker registry address, where Docker must log in to retrieve images. Useful only when using private registry or repository. Default is empty, to use Docker Hub registry.
* *REGISTRY_USER*: Docker registry username, corresponding to a user with read permissions. **Required** for private registry or repository.
* *SERVICE*: Name of service to relaunch (`<stack-name>_<service-name>`). Available and **required** only for *relaunch* action.
* *SERVICES_TO_CHECK*: Names of services to check after deployment, separated by space. Default is `STACK` variable value, but setting this to a valid service name is recommended (`<stack-name>_<service-name>`).
* *SERVICES_TO_DEPLOY*: Names of services to deploy, separated by space. Available only for standard (*docker-compose*) mode. Default is empty, to deploy all defined services.
* *STATUS_CHECK_DELAY*: Seconds to wait before check deployment. Default `120`.
* *STATUS_CHECK_INTERVAL*: Seconds to wait between check iterations. Default `20`.
* *STATUS_CHECK_MIN_HITS*: Minimum number of successful checks to consider deployment as successful. Default `3`.
* *STATUS_CHECK_RETRIES*: Maximum number of checks before considering deployment as failed. Default `10`.
* *USE_IMAGE_DIGEST*: Update service image using digest data when relaunching. Available only for *relaunch* action. Default `0`.

### Your services

When using *deploy* action, you can configure your own services through variables:

* Define any variable whose name is prefixed by `ENV_PREFIX` prefix:
	1. Set variable `docker run ... -e DD_ANY_NAME=value ... deploy`.
	2. `ANY_NAME` will be available into service containers with `value` value.
* Pass any variable as deploy script parameter (without `ENV_PREFIX` prefix):
	1. Set parameter to deploy script: `docker run ... deploy ANY_NAME=value`.
	2. `ANY_NAME` will be available into service containers with `value` value.

## Examples

### Deploy

```
$ ls -a deploy
.  ..  docker-compose.yml  .env

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

$ docker run --rm --name docker-deploy \
	-e SSH_REMOTE=user@domain.net -e DEPLOY_KEY \
	-e STACK=example -e SERVICES_TO_CHECK=example_service-name \
	-e DD_VARIABLE_1="variable 1" \
	-v $(pwd)/deploy:/deploy \
	redmic/docker-docker-deploy \
	deploy VARIABLE_2="variable 2"
```

1. You must define the deploy configuration, a valid `docker-compose.yml` file at least.
2. To authenticate, you must use a **private key** allowed in the remote host.
3. Start service deployment. In this example:
	* to `domain.net` remote host
	* identified as `user`
	* authenticated through a RSA-1024 private key
	* into `example` stack
	* check service `example_service-name` deployment
	* with `VARIABLE_1` and `VARIABLE_2` set in service

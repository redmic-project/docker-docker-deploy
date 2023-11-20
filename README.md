# Docker deploy

Docker deployment utilities for REDMIC infrastructure.
You can use it to deploy your own services, supporting **Docker Compose** (both v1 and v2) and **Docker Swarm** environments.

## Actions

* **deploy**: Perform a service deployment at a Docker environment. Contains 3 stages:
  * *prepare-deploy*: Check dependencies, copy resources to deployment target host (*compose* files, service configurations...), prepare environment variables and directories, etc.
  * *do-deploy*: Launch service at deployment target host. Both standard (using `docker compose`) and *Swarm* (using `docker stack deploy`) modes are supported (deprecated versions too), but *Swarm* mode is recommended (even for single-node clusters).
  * *check-deploy*: Once deployment is done, this stage waits a defined time period for the service to being up and running (or stopped after run successfully). If service status remains stable after several checks, then it is considered successfully deployed.
* **create-nets**: Prepare deployment target host environment creating Docker networks which are external to service definition (not created by service deployment itself, defined as *external* in compose files).
* **relaunch**: Force a previously deployed service to update, relaunching it with the same service configuration. Available only for *Swarm* mode.

## Usage

For REDMIC, we use this image into CI/CD configuration. Deploy jobs are defined into our [GitLab CI configuration](https://gitlab.com/redmic-project/gitlab-ci-templates), but you can run it directly using `docker run`:

```sh
docker run --rm --name docker-deploy \
  -e SSH_REMOTE=ssh-user@host \
  -e DEPLOY_KEY="<your-private-key>" \
  -e STACK=your-stack-name \
  -v $(pwd)/compose.yaml:/compose.yaml \
  -v $(pwd)/.env:/.env \
  redmic/docker-docker-deploy:latest \
  <action> <arg1> <arg2> ...
```

As you can see, configuration is possible through environment variables and by script (`<action>`) parameters.

Using environment variables, you can configure:

* Behaviour of this image itself.
* Deployment target host environment (where you are deploying to) for service deployment configuration and deployed service environment variables (the latter only when action is *deploy* and using the `ENV_PREFIX` prefix in your variable names).

Using script parameters you can set:

* When action is *deploy*, deployment target host environment (where you are deploying to) for service deployment configuration and deployed service environment variables. These parameters overwrite previous environment values, including those defined using the `ENV_PREFIX` prefix.
* When action is *create-nets*, the name of external networks to create.

## Configuration

### This service

You may define these environment variables (**bold** are mandatory):

| Variable name | Default value | Description |
| - | - | - |
| **DEPLOY_KEY** | - | Private key used to authenticate, paired with a public key accepted by remote host. |
| **SSH_REMOTE** | - | SSH user and hostname (DNS or IP) of remote host where you are going to deploy. |
| **STACK** | - | Name of Docker stack (*Swarm* mode) or project (*Compose* mode) used to wrap deployed services. |
| *COMPOSE_ENV_FILE_NAME* | `.env` | Name of variable values definition file. |
| *COMPOSE_FILE* | `compose.yaml` | Name of service definition file. Multiple files are supported, separated by colon (`:`). |
| *DEFAULT_DEPLOY_FILES* | `*compose*.y*ml .env` | Files needed for deployment. Used only if `DEPLOY_DIR_NAME` directory does not exist. |
| *DEPLOY_DIR_NAME* | `deploy` | Name of directory containing files needed for deployment. If directory exists, `DEFAULT_DEPLOY_FILES` is ignored and all contents are copied to deployment target host. |
| *DEPLOY_PATH* | `~` | Path in deployment target host where deployment directory (used to hold temporary files) will be created. |
| *ENV_PREFIX* | `DD_` | Prefix used to identify variables to be defined in deployment target host environment and service, available there without this prefix. Change this if default value collides with the beginning of your variable names. |
| *ENV_SPACE_REPLACEMENT* | `<dd-space>` | Unique string (change this if that is not true for you) used to replace spaces into variable values while handling them. |
| *FORCE_DOCKER_COMPOSE* | `0` | Use always standard (*Compose*) mode instead of Docker *Swarm*, even if it is available at deployment target host. |
| *GREP_BIN* | `grep` | Path to *grep* binary in deployment target host. |
| *OMIT_CLEAN_DEPLOY* | `0` | Leave at deployment target host deployment resources after doing a successful deploy. Useful when using bind mounts or *Compose* secrets (pointing to static content in deployment resources). |
| *REGISTRY_PASS* | - | Docker registry password, corresponding to a user with read permissions. **Required** for private registry or repository. |
| *REGISTRY_URL* | - | Docker registry address, where Docker must log in to retrieve images. Useful only when using private registry or repository. Default is empty, to use Docker Hub registry. |
| *REGISTRY_USER* | - | Docker registry username, corresponding to a user with read permissions. **Required** for private registry or repository. |
| *SERVICE* | - | Name of service to relaunch (`<stack-name>_<service-name>`). Available and **required** only for *relaunch* action. |
| *SERVICES_TO_AUTH* | - | Names of services which need authorization to access to private registry, separated by space. Default is empty, to use service names found into compose files with stack prefix (`<stack-name>_<service-name>`). |
| *SERVICES_TO_CHECK* | - | Names of services to check after deployment, separated by space. Default is empty, to use service names found into compose files with stack prefix (`<stack-name>_<service-name>`). |
| *SERVICES_TO_DEPLOY* | - | Names of services to deploy, separated by space. Available only for standard (*Compose*) mode. Default is empty, to deploy all defined services. |
| *SSH_CONTROL_PERSIST* | `10` | Number of seconds while SSH connection to remote host remain open (useful for short but frequent connections). |
| *SSH_PORT* | `22` | Port used for SSH connection to remote host. |
| *STATUS_CHECK_DELAY* | `120` | Seconds to wait before check deployment. |
| *STATUS_CHECK_INTERVAL* | `20` | Seconds to wait between check iterations. |
| *STATUS_CHECK_MIN_HITS* | `3` | Minimum number of successful checks to consider deployment as successful. |
| *STATUS_CHECK_RETRIES* | `10` | Maximum number of checks before considering deployment as failed. |
| *SWARM_RESOLVE_IMAGE* | `always` | Allows to edit the behaviour of the registry query to resolve image digests and supported platforms (`always`, `changed` or `never`). |
| *USE_IMAGE_DIGEST* | `0` | Update service image using digest data when relaunching. Available only for *relaunch* action. |

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

```sh
$ ls -a deploy
.  ..  compose.yaml  .env

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
  -e SSH_REMOTE=user@domain.net \
  -e DEPLOY_KEY \
  -e STACK=example \
  -e DD_VARIABLE_1="variable 1" \
  -v $(pwd)/deploy:/deploy \
  redmic/docker-docker-deploy \
  deploy VARIABLE_2="variable 2"
```

1. You must define the deploy configuration, a valid `compose.yaml` file at least.
2. To authenticate, you must use a **private key** allowed in the remote host.
3. Start service deployment. In this example:
   * to `domain.net` remote host
   * identified as `user`
   * authenticated through a RSA-1024 private key
   * into `example` stack
   * with `VARIABLE_1` and `VARIABLE_2` set in service

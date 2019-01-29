# Docker deploy

Docker deployment utilities for REDMIC infrastructure. You can use it to deploy your own services into your servers.

## Actions

* **deploy**: Perform a deployment of a service on a remote Docker environment. Contains 3 stages:

  * *prepare-deploy*: Copy resources to remote environment (*docker-compose* files, service configurations, ...), prepare environment variables and directories, etc.

  * *do-deploy*: Launch service on Docker environment. Both standard and Swarm modes are supported on remote Docker environment, but Swarm mode is recommended (even for a single-node clusters).

  * *check-deploy*: Once deployment is done, this stage wait a defined period of time for the service to being up and running (or stopped after run successfully). If service status remains stable after several checks, then it is considered successfully deployed.

* **create-nets**: Prepare remote environment creating Docker networks which are external to service (not created by service deployment itself).

* **relaunch**: Force a previously deployed service to update, relaunching it with the same service configuration.

## Usage

For REDMIC, we use this image from GitLabCI configuration, but you can use it directly like:

```
$ docker run --rm --name docker-deploy \
	-e STACK=your-stack-name -e SSH_REMOTE=ssh-user@ssh-host -e GITLAB_DEPLOY_KEY=<your-private-key> \
	registry.gitlab.com/redmic-project/docker/docker-deploy:latest \
	<action> <VAR1>=<value1> <VAR2>=<value2> ...
```

As you can see, there is configuration through environment variables and by action script parameters. By environment variables, you configure the behaviour of this image itself. The script parameters are used like environment variables, but in the remote environment (where you are deploying to), in order to configure your service.

For environment variables, you may define these variables (**bold** are mandatory):

* **STACK** / **SERVICE**: Name of Docker stack (Swarm mode) or service (standard mode) to deploy.
* **SSH_REMOTE**: SSH user and host of remote machine where you are going to deploy.
* **GITLAB_DEPLOY_KEY**: Private key paired with a public key accepted by remote machine, used to authenticate.
* *COMPOSE_FILE*: Default `docker-compose.yml`.
* *DEPLOY_PATH*: Default `~`.
* *DEPLOY_DIR_NAME*: Default `deploy`.
* *DEFAULT_DEPLOY_FILES*: Default `docker-compose*.yml .env`.
* *REGISTRY_USER*: Default `gitlab-ci-token`.
* *STATUS_CHECK_RETRIES*: Default `10`.
* *STATUS_CHECK_INTERVAL*: Default `20`.
* *STATUS_CHECK_DELAY*: Default `120`.
* *STATUS_CHECK_MIN_HITS*: Default `3`.
* *GREP_BIN*: Default `grep`.

Action may be one of `deploy.sh`, `create-nets.sh` or `relaunch.sh`, and parameters with variable/value depends on your service needs.

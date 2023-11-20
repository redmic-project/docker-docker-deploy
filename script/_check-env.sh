#!/bin/sh

# Se comprueba si está disponible el binario docker en el entorno donde se va a desplegar.
checkDockerCmd="docker --version > /dev/null 2>&1"
if ! ssh ${SSH_PARAMS} "${SSH_REMOTE}" ${checkDockerCmd}
then
	echo -e "\n${FAIL_COLOR}Docker is not available at deployment target host environment!${NULL_COLOR}"
	eval "${closeSshCmd}"
	exit 1
fi

# Se comprueba si la versión de Docker en el entorno donde se va a desplegar es >= v23.0.0.
checkDocker23Cmd="[ \$(docker --version | sed -r 's/.* ([0-9]+)\..*/\1/g') -ge 23 ]"
ssh ${SSH_PARAMS} "${SSH_REMOTE}" ${checkDocker23Cmd}
docker23CompatibleTarget=${?}

# Se comprueba si se desea y si es posible desplegar en modo Swarm.
checkDeploymentTypeCmd="[ ${FORCE_DOCKER_COMPOSE} -eq 0 ] && docker stack ls > /dev/null 2>&1"
ssh ${SSH_PARAMS} "${SSH_REMOTE}" ${checkDeploymentTypeCmd}
deployingToSwarm=${?}

# Se comprueba si está disponible el plugin compose de docker o el antiguo binario docker-compose.
if [ ${docker23CompatibleTarget} -eq 0 ]
then
	checkDockerComposeCmd="docker compose version > /dev/null 2>&1"
	dockerVersionLabel=">= v23"
	composeVersionLabel="current >=v2 plugin"
else
	checkDockerComposeCmd="docker-compose version > /dev/null 2>&1"
	dockerVersionLabel="< v23"
	composeVersionLabel="deprecated v1 binary"
fi

echo -e "  ${INFO_COLOR}host Docker version [ ${DATA_COLOR}${dockerVersionLabel}${INFO_COLOR} ]${NULL_COLOR}"

if [ ${deployingToSwarm} -eq 0 ]
then
	deploymentTypeLabel="Swarm"

	# Prepara los argumentos necesarios para indicar los ficheros compose a usar, para swarm o para compose.
	swarmComposeFileSplitted=$(echo ${COMPOSE_FILE} | sed 's/:/ -c /g')
else
	deploymentTypeLabel="Compose"

	# Prepara los argumentos necesarios para indicar los ficheros compose a usar, para compose.
	standardComposeFileSplitted=$(echo ${COMPOSE_FILE} | sed 's/:/ -f /g')

	if ! ssh ${SSH_PARAMS} "${SSH_REMOTE}" ${checkDockerComposeCmd}
	then
		echo -e "\n${FAIL_COLOR}Docker Compose (${composeVersionLabel}) is not available at deployment target host environment!${NULL_COLOR}"
		eval "${closeSshCmd}"
		exit 1
	fi

	echo -e "  ${INFO_COLOR}host Docker Compose version [ ${DATA_COLOR}${composeVersionLabel}${INFO_COLOR} ]${NULL_COLOR}"
fi

echo -e "  ${INFO_COLOR}deployment type [ ${DATA_COLOR}${deploymentTypeLabel}${INFO_COLOR} ]${NULL_COLOR}"

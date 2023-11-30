#!/bin/sh

# Se comprueba si está disponible el binario docker en el entorno donde se va a desplegar.
checkDockerCmd="command -v docker > /dev/null"
if ! runRemoteCmd "${checkDockerCmd}"
then
	echo -e "\n${FAIL_COLOR}Docker is not available at deployment target host environment!${NULL_COLOR}"
	eval "${closeSshCmd}"
	exit 1
fi

# Se obtiene la versión de Docker disponible en el entorno donde se va a desplegar.
getDockerVersionCmd="docker version --format '{{.Server.Version}}'"
dockerVersion=$(runRemoteCmd "${getDockerVersionCmd}")

echo -e "  ${INFO_COLOR}host Docker version [ ${DATA_COLOR}${dockerVersion}${INFO_COLOR} ]${NULL_COLOR}"

# Se comprueba si la versión de Docker en el entorno donde se va a desplegar es >= v23.0.0.
dockerMajorVersion=$(echo "${dockerVersion}" | cut -d '.' -f 1)
[ "${dockerMajorVersion}" -ge 23 ]
docker23CompatibleTarget=${?}

# Se comprueba si se desea y si es posible desplegar en modo Swarm.
if [ ${FORCE_DOCKER_COMPOSE} -ne 0 ]
then
	deployingToSwarm=1
else
	checkSwarmManagerAvailabilityCmd="[ \$(docker info --format '{{.Swarm.ControlAvailable}}') = true ]"
	runRemoteCmd "${checkSwarmManagerAvailabilityCmd}"
	deployingToSwarm=${?}
fi

if [ ${deployingToSwarm} -eq 0 ]
then
	deploymentTypeLabel="Swarm"

	# Prepara los argumentos necesarios para indicar los ficheros compose a usar, para swarm o para compose.
	swarmComposeFileSplitted=$(echo ${COMPOSE_FILE} | sed 's/:/ -c /g')
else
	deploymentTypeLabel="Compose"

	# Prepara los argumentos necesarios para indicar los ficheros compose a usar, para compose.
	standardComposeFileSplitted=$(echo ${COMPOSE_FILE} | sed 's/:/ -f /g')

	# Se comprueba si está disponible el plugin compose de docker o el antiguo binario docker-compose.
	if [ ${docker23CompatibleTarget} -eq 0 ]
	then
		composeBaseCmd="docker compose"
	else
		composeBaseCmd="docker-compose"

		checkDockerComposeBinaryCmd="command -v docker-compose > /dev/null"
		if ! runRemoteCmd "${checkDockerComposeBinaryCmd}"
		then
			echo -e "\n${FAIL_COLOR}Legacy docker-compose binary is not available at deployment target host environment!${NULL_COLOR}"
			eval "${closeSshCmd}"
			exit 1
		fi
	fi

	# Se obtiene la versión de Docker Compose disponible en el entorno donde se va a desplegar.
	getComposeVersionCmd="${composeBaseCmd} version --short"
	composeVersion=$(runRemoteCmd "${getComposeVersionCmd}")

	echo -e "  ${INFO_COLOR}host Docker Compose version [ ${DATA_COLOR}${composeVersion}${INFO_COLOR} ]${NULL_COLOR}"
fi

echo -e "  ${INFO_COLOR}deployment type [ ${DATA_COLOR}${deploymentTypeLabel}${INFO_COLOR} ]${NULL_COLOR}"

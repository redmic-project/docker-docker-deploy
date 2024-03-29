#!/bin/sh

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

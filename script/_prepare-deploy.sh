#!/bin/sh

# Se comprueba si está disponible el binario docker en el entorno donde se va a desplegar.
checkDockerCmd="docker --version > /dev/null 2>&1"
if ! ssh ${SSH_PARAMS} "${SSH_REMOTE}" ${checkDockerCmd}
then
	echo -e "${FAIL_COLOR}Docker is not available at deployment target host environment!${NULL_COLOR}"
	exit 1
fi

# Se comprueba si la versión de Docker en el entorno donde se va a desplegar es >= v23.0.0.
checkDocker23Cmd="[ \$(docker --version | sed -r 's/.* ([0-9]+)\..*/\1/g') -ge 23 ]"
ssh ${SSH_PARAMS} "${SSH_REMOTE}" ${checkDocker23Cmd}
docker23CompatibleTarget=${?}

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
if ! ssh ${SSH_PARAMS} "${SSH_REMOTE}" ${checkDockerComposeCmd}
then
	echo -e "${FAIL_COLOR}Docker Compose (${composeVersionLabel}) is not available at deployment target host environment!${NULL_COLOR}"
	exit 1
fi

# Se comprueba si se desea y si es posible desplegar en modo Swarm.
checkDeploymentTypeCmd="[ ${FORCE_DOCKER_COMPOSE} -eq 0 ] && docker stack ls > /dev/null 2>&1"
ssh ${SSH_PARAMS} "${SSH_REMOTE}" ${checkDeploymentTypeCmd}
deployingToSwarm=${?}

# Se preparan rutas de despliegue.
randomValue="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)"
deployHomeParent="${DEPLOY_PATH}/docker-deploy"
deployHome="${deployHomeParent}/${randomValue}"

# Se comprueba si existe directorio con recursos de despliegue o están en la raíz del proyecto.
if [ -d "${DEPLOY_DIR_NAME}" ]
then
	cd "${DEPLOY_DIR_NAME}"
	deployFiles="-r $(pwd)"
	createDirCmd="mkdir -p ${deployHomeParent}"
else
	deployFiles=${DEFAULT_DEPLOY_FILES}
	createDirCmd="mkdir -p ${deployHome}"
fi

# Prepara ficheros compose sin versión si se despliega en modo Swarm a un entorno con versión Docker < v23.
restoreComposeFilesCmd=""
if [ ${deployingToSwarm} -eq 0 ] && [ ${docker23CompatibleTarget} -ne 0 ]
then
	for composeFile in $(echo "${COMPOSE_FILE}" | sed 's/:/ /g')
	do
		if ! grep -q '^version:' "${composeFile}"
		then
			cp -a "${composeFile}" "${composeFile}-original"
			sed -i "1s/^/version: '3.8'\n/g" "${composeFile}"
			restoreComposeFilesCmd="${restoreComposeFilesCmd} mv \"${composeFile}-original\" \"${composeFile}\" ;"
		fi
	done
fi

# Se obtienen los nombres de servicio presentes en ficheros compose, con prefijo de stack.
servicesInComposeFiles=$(docker --log-level error compose config --services | sed "s/^/${STACK}_/g" | tr '\n' ' ')
servicesToDeployLabel=${SERVICES_TO_DEPLOY:-${servicesInComposeFiles}}

echo -e "${DATA_COLOR}Docker deploy${INFO_COLOR} is about to perform a deployment at host ${DATA_COLOR}${remoteHost}${INFO_COLOR} ..${NULL_COLOR}"
echo -e "  ${INFO_COLOR}host Docker version [ ${DATA_COLOR}${dockerVersionLabel}${INFO_COLOR} ]${NULL_COLOR}"
echo -e "  ${INFO_COLOR}host Docker Compose version [ ${DATA_COLOR}${composeVersionLabel}${INFO_COLOR} ]${NULL_COLOR}"
echo -e "  ${INFO_COLOR}services to deploy [ ${DATA_COLOR}${servicesToDeployLabel}${INFO_COLOR}]${NULL_COLOR}"

echo -e "\n${INFO_COLOR}Setting environment variables to local and deployment target host environments ..${NULL_COLOR}"
echo -en "  ${INFO_COLOR}variable names [ ${DATA_COLOR}STACK${INFO_COLOR}"

envDefs="STACK=${STACK}"

addVariableToEnv() {
	envDefs="${envDefs}\\n${1}"
	variableName=$(echo "${1}" | cut -d '=' -f 1)
	echo -en "${INFO_COLOR}, ${DATA_COLOR}${variableName}${INFO_COLOR}"
}

# Se toma como base el entorno actual, incluyendo solo las variables cuyo nombre comience con el prefijo deseado.
currEnv=$(env | grep "^${ENV_PREFIX}" | sed "s/${ENV_PREFIX}//g" | sed "s/ /${ENV_SPACE_REPLACEMENT}/g")
for currEnvItem in ${currEnv}
do
	cleanItem=$(echo "${currEnvItem}" | sed "s/${ENV_SPACE_REPLACEMENT}/ /g")
	addVariableToEnv "${cleanItem}"
done

# Los argumentos pasados (opcionales) se tratan como variables. Sobreescriben a los valores procedentes del entorno.
for arg in "${@}"
do
	addVariableToEnv "${arg}"
done

# Se prepara el fichero .env para usarlas en la máquina destino y se setean en este entorno también.
cp -a .env .env-original
echo -e ${envDefs} >> .env

echo -e " ]${NULL_COLOR}"
echo -e "\n${INFO_COLOR}Checking deployment configuration in compose files ..${NULL_COLOR}"
echo -e "  ${INFO_COLOR}compose files [ ${DATA_COLOR}${COMPOSE_FILE}${INFO_COLOR} ]${NULL_COLOR}"
echo -en "  ${INFO_COLOR}check command [ ${DATA_COLOR}"

# Antes de continuar, se comprueba que la configuración de despliegue sea válida para compose o swarm.
validComposeMessage="${PASS_COLOR}Valid compose configuration!${NULL_COLOR}"
invalidComposeMessage="${FAIL_COLOR}Invalid compose configuration!${NULL_COLOR}"

if [ ${docker23CompatibleTarget} -eq 0 ] && [ ${deployingToSwarm} -eq 0 ]
then
	echo -e "docker stack config${INFO_COLOR} ]${NULL_COLOR}\n"
	swarmComposeFileSplitted=$(echo ${COMPOSE_FILE} | sed 's/:/ -c /g')

	if docker stack config -q -c ${swarmComposeFileSplitted}
	then
		echo -e "${validComposeMessage}"
	else
		echo -e "${invalidComposeMessage}"
		exit 1
	fi
else
	echo -e "docker compose config${INFO_COLOR} ]${NULL_COLOR}\n"

	if docker compose config -q
	then
		echo -e "${validComposeMessage}"
	else
		echo -e "${invalidComposeMessage}"
		exit 1
	fi
fi

echo -e "\n${INFO_COLOR}Sending deployment resources to host ${DATA_COLOR}${remoteHost}${INFO_COLOR} ..${NULL_COLOR}"
echo -e "  ${INFO_COLOR}deployment path [ ${DATA_COLOR}${deployHome}${INFO_COLOR} ]${NULL_COLOR}"
echo -e "  ${INFO_COLOR}deployment files [ ${DATA_COLOR}${deployFiles}${INFO_COLOR} ]${NULL_COLOR}\n"

# Se crea el directorio donde guardar los ficheros de despliegue del servicio.
if ! ssh ${SSH_PARAMS} "${SSH_REMOTE}" ${createDirCmd}
then
	echo -e "${FAIL_COLOR}Deployment path ${DATA_COLOR}${deployHome}${FAIL_COLOR} creation failed!${NULL_COLOR}"
	ssh ${SSH_PARAMS} -q -O exit "${SSH_REMOTE}"
	exit 1
fi

# Se envían a su destino los ficheros de despliegue del servicio y se restaura el .env local.
scp ${SSH_PARAMS} ${deployFiles} "${SSH_REMOTE}:${deployHome}"
sendResourcesExitCode=${?}

# Se restauran los ficheros modificados localmente.
mv .env-original .env
if [ ! -z "${restoreComposeFilesCmd}" ]
then
	echo -e "${INFO_COLOR}Detected compose files without version for Swarm deployment at target host with Docker version < v23, automatically set ${DATA_COLOR}version: '3.8'${NULL_COLOR}\n"
	eval "${restoreComposeFilesCmd}"
fi

if [ ${sendResourcesExitCode} -eq 0 ]
then
	echo -e "${PASS_COLOR}Deployment resources successfully sent!${NULL_COLOR}"
else
	echo -e "${FAIL_COLOR}Deployment resources sending failed!${NULL_COLOR}"
	ssh ${SSH_PARAMS} -q -O exit "${SSH_REMOTE}"
	exit 1
fi

#!/bin/sh

# Se preparan rutas de despliegue.
randomValue="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)"
deployHomeParent="${DEPLOY_PATH}/docker-deploy"
deployHome="${deployHomeParent}/${randomValue}"

# Se preparan rutas de recursos de despliegue y creación de directorio destino, según exista directorio dedicado o no.
if [ "${movedToDeployDir}" -eq 1 ]
then
	deployFiles="-r $(pwd)"
	createDirCmd="mkdir -p ${deployHomeParent}"
else
	deployFiles=${DEFAULT_DEPLOY_FILES}
	createDirCmd="mkdir -p ${deployHome}"
fi

echo -e "\n${INFO_COLOR}Sending deployment resources to host ${DATA_COLOR}${remoteHost}${INFO_COLOR} ..${NULL_COLOR}"

echo -e "  ${INFO_COLOR}deployment path [ ${DATA_COLOR}${deployHome}${INFO_COLOR} ]${NULL_COLOR}"
echo -e "  ${INFO_COLOR}deployment files [ ${DATA_COLOR}${deployFiles}${INFO_COLOR} ]${NULL_COLOR}\n"

# Se crea el directorio donde guardar los ficheros de despliegue del servicio.
if ! runRemoteCmd "${createDirCmd}"
then
	echo -e "${FAIL_COLOR}Deployment path ${DATA_COLOR}${deployHome}${FAIL_COLOR} creation failed!${NULL_COLOR}"
	eval "${restoreEnvFileCmd}"
	eval "${closeSshCmd}"
	exit 1
fi

# Prepara ficheros compose sin versión si se despliega en modo Swarm a un entorno con versión Docker < v23.
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

# Se envían a su destino los ficheros de despliegue del servicio.
scp ${SSH_PARAMS} ${deployFiles} "${SSH_REMOTE}:${deployHome}"
sendResourcesExitCode=${?}

# Se restauran los ficheros modificados localmente.
eval "${restoreEnvFileCmd}"
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
	eval "${closeSshCmd}"
	exit 1
fi

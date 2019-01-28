#!/bin/sh

echo -e "\n${INFO_COLOR}Preparing deploy configuration and resources ..${NULL_COLOR}"

# Se comprueba si se despliega desde dentro de 'deploy' o desde la raíz del proyecto.
if [ -d "${DEPLOY_DIR_NAME}" ]
then
	cd "${DEPLOY_DIR_NAME}"
	deployFiles="-r ./."
else
	deployFiles=${DEFAULT_DEPLOY_FILES}
fi

echo -e "\n${INFO_COLOR}Setting environment variables to local and remote environments ..${NULL_COLOR}"
echo -en "  ${INFO_COLOR}variable names [ ${DATA_COLOR}SERVICE${INFO_COLOR}, ${DATA_COLOR}STACK${INFO_COLOR}"

# Los argumentos pasados (opcionales) se tratan como variables de entorno.
# Se prepara el fichero .env para usarlas en la máquina destino y se setean en este entorno también.
envDefs="SERVICE=${SERVICE}\\nSTACK=${STACK}"
for arg in "${@}"
do
	export "${arg}"
	envDefs="${envDefs}\\n${arg}"
	variableName=$(echo "$arg" | cut -f 1 -d '=')
	echo -en "${INFO_COLOR}, ${DATA_COLOR}${variableName}${INFO_COLOR}"
done
echo -e ${envDefs} >> .env
echo -e " ]${NULL_COLOR}"

echo -e "\n${INFO_COLOR}Checking deploy configuration in docker-compose files ..${NULL_COLOR}"
echo -e "  ${INFO_COLOR}compose files [ ${DATA_COLOR}${COMPOSE_FILE}${INFO_COLOR} ]${NULL_COLOR}\n"

# Antes de continuar, se comprueba que la configuración de despliegue sea válida.
if docker-compose config > /dev/null
then
	echo -e "${PASS_COLOR}Valid docker-compose configuration!${NULL_COLOR}"
else
	echo -e "${FAIL_COLOR}Invalid docker-compose configuration!${NULL_COLOR}"
	exit 1
fi

randomValue="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)"
DEPLOY_HOME="${DEPLOY_PATH}/docker-deploy/${randomValue}"

echo -e "\n${INFO_COLOR}Sending deploy resources to remote ${DATA_COLOR}${remoteHost}${INFO_COLOR} ..${NULL_COLOR}"
echo -e "  ${INFO_COLOR}deploy path [ ${DATA_COLOR}${DEPLOY_HOME}${INFO_COLOR} ]${NULL_COLOR}"
echo -e "  ${INFO_COLOR}deploy files [ ${DATA_COLOR}${deployFiles}${INFO_COLOR} ]${NULL_COLOR}\n"

# Se crea el directorio donde guardar los ficheros de despliegue del servicio.
createDirCmd="mkdir -p ${DEPLOY_HOME}"
if ! ssh ${SSH_PARAMS} "${SSH_REMOTE}" ${createDirCmd}
then
	echo -e "${FAIL_COLOR}Deploy path ${DATA_COLOR}${DEPLOY_HOME}${FAIL_COLOR} creation failed!${NULL_COLOR}"
	ssh ${SSH_PARAMS} -q -O exit "${SSH_REMOTE}"
	exit 1
fi

# Se envían a su destino los ficheros de despliegue del servicio.
if scp ${SSH_PARAMS} ${deployFiles} "${SSH_REMOTE}:${DEPLOY_HOME}"
then
	echo -e "${PASS_COLOR}Deploy resources successfully sent!${NULL_COLOR}"
else
	echo -e "${FAIL_COLOR}Deploy resources sending failed!${NULL_COLOR}"
	ssh ${SSH_PARAMS} -q -O exit "${SSH_REMOTE}"
	exit 1
fi

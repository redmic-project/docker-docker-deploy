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

# Los argumentos pasados (opcionales) se tratan como variables de entorno.
# Se prepara el fichero .env para usarlas en la máquina destino y se setean en este entorno también.
envDefs="SERVICE=${SERVICE}\\nSTACK=${STACK}"
for arg in "${@}"
do
	export "${arg}"
	envDefs="${envDefs}\\n${arg}"
done
echo -e ${envDefs} >> .env

echo -e "\n${INFO_COLOR}Checking deploy configuration in docker-compose files ..${NULL_COLOR}"
echo -e "  ${INFO_COLOR}compose files [ ${DATA_COLOR}${COMPOSE_FILE}${INFO_COLOR} ]${NULL_COLOR}"

# Antes de continuar, se comprueba que la configuración de despliegue sea válida.
docker-compose config > /dev/null
if [ "${?}" -ne "0" ]
then
	echo -e "${FAIL_COLOR}Invalid docker-compose configuration!${NULL_COLOR}"
	exit 1
else
	echo -e "${PASS_COLOR}Valid docker-compose configuration!${NULL_COLOR}"
fi

DEPLOY_HOME="${DEPLOY_PATH}/docker/${STACK:-${SERVICE}}"

echo -e "\n${INFO_COLOR}Sending deploy resources to remote ..${NULL_COLOR}"
echo -e "  ${INFO_COLOR}deploy path [ ${DATA_COLOR}${DEPLOY_HOME}${INFO_COLOR} ]${NULL_COLOR}"
echo -e "  ${INFO_COLOR}deploy files [ ${DATA_COLOR}${deployFiles}${INFO_COLOR} ]${NULL_COLOR}"

# Se crea el directorio donde guardar los ficheros de despliegue del servicio.
createDirCmd="mkdir -p ${DEPLOY_HOME}"
ssh ${SSH_PARAMS} "${SSH_REMOTE}" ${createDirCmd}

# Se envían a su destino los ficheros de despliegue del servicio.
scp ${SSH_PARAMS} ${deployFiles} "${SSH_REMOTE}:${DEPLOY_HOME}"

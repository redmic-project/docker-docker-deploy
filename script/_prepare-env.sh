#!/bin/sh

# Se cambia la ruta si existe directorio con recursos de despliegue, si no se permanece en la raíz del proyecto.
if [ -d "${DEPLOY_DIR_NAME}" ]
then
	cd "${DEPLOY_DIR_NAME}"
	movedToDeployDir=1
fi

# Se obtienen los nombres de servicio presentes en ficheros compose, con prefijo de stack.
servicesInComposeFiles=$(docker compose config --services 2> /dev/null | sed "s/^/${STACK}_/g" | tr '\n' ' ')
servicesToDeployLabel=${SERVICES_TO_DEPLOY:-${servicesInComposeFiles}}

echo -e "  ${INFO_COLOR}services to deploy [ ${DATA_COLOR}${servicesToDeployLabel}${INFO_COLOR}]${NULL_COLOR}\n"
echo -e "${PASS_COLOR}Host environment is valid for deployment!${NULL_COLOR}"

echo -e "\n${INFO_COLOR}Setting environment variables to local and deployment target host environments ..${NULL_COLOR}"
echo -en "  ${INFO_COLOR}variable names [ ${DATA_COLOR}STACK${INFO_COLOR}"

envDefs="STACK=${STACK}"

addVariableToEnv() {
	envDefs="${envDefs}\\n${1}"
	variableName=$(echo "${1}" | cut -d '=' -f 1)
	echo -en "${INFO_COLOR}, ${DATA_COLOR}${variableName}${INFO_COLOR}"
}

# Incluye desde el entorno actual sólo las variables con el prefijo deseado, aceptando espacios en su valor.
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

# Si existen credenciales de registry, se incorporan para poder obtenerlas de forma segura después.
if [ ! -z "${REGISTRY_USER}" ]
then
	ddRegistryPassVarName=DOCKER_DEPLOY_REGISTRY_PASS
	addVariableToEnv "${ddRegistryPassVarName}=${REGISTRY_PASS}"
fi

# Se copia el fichero de valores de entorno, antes de modificarlo. Además, prepara su restauración posterior.
restoreEnvFileCmd="mv '${COMPOSE_ENV_FILE_NAME}-original' '${COMPOSE_ENV_FILE_NAME}'"
if [ ! -f "${COMPOSE_ENV_FILE_NAME}" ]
then
	touch "${COMPOSE_ENV_FILE_NAME}"
	restoreEnvFileCmd="${restoreEnvFileCmd}; rm '${COMPOSE_ENV_FILE_NAME}'"
fi
cp -a "${COMPOSE_ENV_FILE_NAME}" "${COMPOSE_ENV_FILE_NAME}-original"

# Se vuelcan las variables recopiladas al fichero de valores de entorno, para usarlas en la máquina destino.
echo -e ${envDefs} >> "${COMPOSE_ENV_FILE_NAME}"

echo -e " ]${NULL_COLOR}\n"
echo -e "${PASS_COLOR}All environment variables set!${NULL_COLOR}"

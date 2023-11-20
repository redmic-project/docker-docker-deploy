#!/bin/sh

# Se cambia la ruta si existe directorio con recursos de despliegue, si no se permanece en la raíz del proyecto.
if [ -d "${DEPLOY_DIR_NAME}" ]
then
	cd "${DEPLOY_DIR_NAME}"
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
restoreEnvFileCmd="mv .env-original .env"
if [ ! -f .env ]
then
	touch .env
	restoreEnvFileCmd="${restoreEnvFileCmd}; rm .env"
fi
cp -a .env .env-original
echo -e ${envDefs} >> .env

echo -e " ]${NULL_COLOR}\n"
echo -e "${PASS_COLOR}All environment variables set!${NULL_COLOR}"

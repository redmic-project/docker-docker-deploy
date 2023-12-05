#!/bin/sh

echo -e "\n${INFO_COLOR}Checking deployment configuration in compose files ..${NULL_COLOR}"
echo -e "  ${INFO_COLOR}compose files [ ${DATA_COLOR}${COMPOSE_FILE}${INFO_COLOR} ]${NULL_COLOR}"
echo -en "  ${INFO_COLOR}check command [ ${DATA_COLOR}"

# Antes de continuar, se comprueba que la configuración de despliegue sea válida para compose o swarm.
tempEnvFile=".env-config"
if [ ${docker23CompatibleTarget} -eq 0 ] && [ ${deployingToSwarm} -eq 0 ]
then
	echo -e "docker stack config${INFO_COLOR} ]${NULL_COLOR}\n"

	grep -v '^[#| ]' "${COMPOSE_ENV_FILE_NAME}" | sed -r "s/(\w+)=(.*)/export \1='\2'/g" > "${tempEnvFile}"

	env -i /bin/sh -c "\
		. $(pwd)/${tempEnvFile} && \
		rm $(pwd)/${tempEnvFile} && \
		/usr/local/bin/docker stack config -c ${swarmComposeFileSplitted} > /dev/null"
else
	echo -e "docker compose config${INFO_COLOR} ]${NULL_COLOR}\n"

	if [ ${OMIT_COMPOSE_ENV_FILE_INTERPOLATION} -eq 0 ]
	then
		envConfigContent=""
		while IFS= read -r envLine
		do
			if [ -z "${envLine}" ] || echo "${envLine}" | grep -q '^[#| ]'
			then
				continue
			else
				variableName=$(echo "${envLine}" | cut -d '=' -f 1)
				variableValue=$(echo "${envLine}" | cut -d '=' -f 2-)

				# Si la variable ya tiene valor entrecomillado simple o los dólares duplicados, se usa tal cual
				if echo "${variableValue}" | grep -q '\$\$' || echo "${variableValue}" | grep -q "^'"
				then
					envConfigContent="${envConfigContent}${variableName}=${variableValue}\\n"
				else
					envConfigContent="${envConfigContent}${variableName}='${variableValue}'\\n"
				fi
			fi
		done < "${COMPOSE_ENV_FILE_NAME}"
		echo -e "${envConfigContent}" > "${tempEnvFile}"
	else
		tempEnvFile="${COMPOSE_ENV_FILE_NAME}"
	fi

	docker compose --env-file "${tempEnvFile}" config -q

	rm "${tempEnvFile}"
fi

if [ ${?} -eq 0 ]
then
	echo -e "${PASS_COLOR}Valid compose configuration!${NULL_COLOR}"
else
	echo -e "\n${FAIL_COLOR}Invalid compose configuration!${NULL_COLOR}"
	eval "${restoreEnvFileCmd}"
	eval "${closeSshCmd}"
	exit 1
fi

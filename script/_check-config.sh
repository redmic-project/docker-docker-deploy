#!/bin/sh

echo -e "\n${INFO_COLOR}Checking deployment configuration in compose files ..${NULL_COLOR}"
echo -e "  ${INFO_COLOR}compose files [ ${DATA_COLOR}${COMPOSE_FILE}${INFO_COLOR} ]${NULL_COLOR}"
echo -en "  ${INFO_COLOR}check command [ ${DATA_COLOR}"

# Antes de continuar, se comprueba que la configuración de despliegue sea válida para compose o swarm.
if [ ${docker23CompatibleTarget} -eq 0 ] && [ ${deployingToSwarm} -eq 0 ]
then
	echo -e "docker stack config${INFO_COLOR} ]${NULL_COLOR}\n"
	grep -v '^[#| ]' "${COMPOSE_ENV_FILE_NAME}" | sed -r "s/(\w+)=(.*)/export \1='\2'/g" > .env-config

	env -i /bin/sh -c "\
		. $(pwd)/.env-config && \
		rm $(pwd)/.env-config && \
		/usr/local/bin/docker stack config -c ${swarmComposeFileSplitted} > /dev/null"
else
	echo -e "docker compose config${INFO_COLOR} ]${NULL_COLOR}\n"

	docker compose --env-file "${COMPOSE_ENV_FILE_NAME}" config -q
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

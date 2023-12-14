#!/bin/sh

servicesFoundByName=$(runRemoteCmd "docker service ls -f 'name=${SERVICE}' --format '{{.Name}}'")
servicesSeparatorCount=$(echo "${servicesFoundByName}" | grep -c ' ')

if [ "${servicesSeparatorCount}" -ne 0 ]
then
	serviceToRelaunch=$(echo "${servicesFoundByName}" | cut -d ' ' -f 1)

	echo -e "\n${INFO_COLOR}Found more than one service filtering by name ${DATA_COLOR}${SERVICE}${INFO_COLOR} ..${NULL_COLOR}"
	echo -e "  ${INFO_COLOR}services [ ${DATA_COLOR}${servicesFoundByName}${INFO_COLOR} ]${NULL_COLOR}"
	echo -e "  ${INFO_COLOR}will relaunch only ${DATA_COLOR}${serviceToRelaunch}${INFO_COLOR} service${NULL_COLOR}"
else
	serviceToRelaunch="${SERVICE}"
fi

if [ -z "${serviceToRelaunch}" ]
then
	echo -e "\n${FAIL_COLOR}Service to relaunch not found at remote!${NULL_COLOR}"
	eval "${closeSshCmd}"
	exit 1
fi

if [ "${SWARM_RESOLVE_IMAGE}" = "never" ]
then
	serviceUpdateAdditionalArgs="--no-resolve-image"
fi

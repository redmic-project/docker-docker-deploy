#!/bin/sh

servicesFoundByName=$(runRemoteCmd "docker service ls -f 'name=${SERVICE}' --format '{{.Name}}'")
servicesSeparatorCount=$(echo "${servicesFoundByName}" | wc -l)

if [ "${servicesSeparatorCount}" -ne 1 ]
then
	servicesToRelaunch=$(echo "${servicesFoundByName}" | tr '\n' ' ')
	serviceToRelaunch=$(echo "${servicesToRelaunch}" | cut -d ' ' -f 1)

	echo -e "\n${INFO_COLOR}Found more than one service filtering by name ${DATA_COLOR}${SERVICE}${INFO_COLOR} ..${NULL_COLOR}"
	echo -e "  ${INFO_COLOR}services [ ${DATA_COLOR}${servicesToRelaunch}${INFO_COLOR} ]${NULL_COLOR}"
	echo -e "  ${INFO_COLOR}will relaunch only ${DATA_COLOR}${serviceToRelaunch}${INFO_COLOR} service${NULL_COLOR}\n"
elif [ ! -z "${servicesFoundByName}" ]
then
	serviceToRelaunch="${SERVICE}"

	echo -e "  ${INFO_COLOR}service found [ ${DATA_COLOR}${serviceToRelaunch}${INFO_COLOR} ]${NULL_COLOR}\n"
else
	echo -e "\n${FAIL_COLOR}Service to relaunch not found at remote!${NULL_COLOR}"
	eval "${closeSshCmd}"
	exit 1
fi

if [ "${OMIT_WAITING_TO_CONVERGE}" -ne 0 ]
then
	serviceUpdateAdditionalArgs="${serviceUpdateAdditionalArgs} --detach"
fi

if [ "${SWARM_RESOLVE_IMAGE}" = "never" ]
then
	serviceUpdateAdditionalArgs="${serviceUpdateAdditionalArgs} --no-resolve-image"
fi

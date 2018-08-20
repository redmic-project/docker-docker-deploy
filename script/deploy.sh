#!/bin/sh

. _definitions.sh

if [ -z "${SERVICE}" ] && [ -z "${STACK}" ]
then
	echo -e "${INFO_COLOR}If using standard Docker environment:${NULL_COLOR}"
	echo -e "  ${FAIL_COLOR}You must define 'SERVICE' in environment, with the name of service to run (as defined in compose files, like 'service-to-deploy')${NULL_COLOR}"

	echo -e "${INFO_COLOR}If using Docker Swarm environment:${NULL_COLOR}"
	echo -e "  ${FAIL_COLOR}You must define 'STACK' in environment, with the name of stack to deploy (stack will include all services defined in compose files)${NULL_COLOR}"

	exit 1
fi

. _ssh-config.sh

. _prepare-deploy.sh

. _do-deploy.sh

echo -e "\n${INFO_COLOR}Waiting ${DATA_COLOR}${STATUS_CHECK_DELAY}${INFO_COLOR}s before checking deployment ..${NULL_COLOR}"
sleep ${STATUS_CHECK_DELAY}

. _check-deploy.sh

#!/bin/sh

. _definitions.sh

if [ -z "${STACK}" ]
then
	echo -e "${FAIL_COLOR}You must define 'STACK' in environment, with the name of stack to deploy (stack will include all services defined in compose files)${NULL_COLOR}"
	exit 1
fi

. _ssh-config.sh

. _prepare-deploy.sh

. _do-deploy.sh

echo -e "\n${INFO_COLOR}Waiting ${DATA_COLOR}${STATUS_CHECK_DELAY}${INFO_COLOR}s before checking deployment ..${NULL_COLOR}"
sleep ${STATUS_CHECK_DELAY}

. _check-deploy.sh

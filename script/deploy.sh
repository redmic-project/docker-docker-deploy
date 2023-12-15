#!/bin/sh

. _definitions.sh

if [ -z "${STACK}" ]
then
	echo -e "${FAIL_COLOR}You must define 'STACK' in environment, with the name of stack to deploy (stack will include all services defined in compose files)${NULL_COLOR}"
	exit 1
fi

. _ssh-config.sh

echo -e "${INFO_COLOR}Performing a deployment at host ${DATA_COLOR}${remoteHost}${INFO_COLOR} ..${NULL_COLOR}"

. _check-env.sh
. _check-mode.sh
. _prepare-env.sh
. _check-config.sh
. _prepare-deploy.sh

. _do-deploy.sh

if [ "${OMIT_STATUS_CHECK}" -eq 0 ]
then
	echo -e "\n${INFO_COLOR}Waiting ${DATA_COLOR}${STATUS_CHECK_DELAY}s${INFO_COLOR} before checking deployment ..${NULL_COLOR}"
	sleep ${STATUS_CHECK_DELAY}

	. _check-deploy.sh
else
	echo -e "\n${INFO_COLOR}Omitting deployment check${NULL_COLOR}"
fi

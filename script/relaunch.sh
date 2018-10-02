#!/bin/sh

. _definitions.sh

if [ -z "${SERVICE}" ]
then
	echo -e "${FAIL_COLOR}You must define 'SERVICE' in environment, with the name of service to relaunch${NULL_COLOR}"
	exit 1
fi

. _ssh-config.sh

ssh ${SSH_PARAMS} "${SSH_REMOTE}" "docker service update --force ${SERVICE}"

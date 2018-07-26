#!/bin/sh

. _definitions.sh

if [ -z "${SERVICE}" ] ;
then
	echo -e "${FAIL_COLOR}You must define 'SERVICE' in environment, with the name of service to run (as defined in compose files, like 'service-to-deploy')${NULL_COLOR}"
	exit 1
fi

. _ssh-config.sh

. _prepare-deploy.sh
. _do-deploy.sh

sleep ${STATUS_CHECK_DELAY}

. _check-deploy.sh

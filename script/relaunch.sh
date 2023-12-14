#!/bin/sh

. _definitions.sh

if [ -z "${SERVICE}" ]
then
	echo -e "${FAIL_COLOR}You must define 'SERVICE' in environment, with the name of service to relaunch${NULL_COLOR}"
	exit 1
fi

. _ssh-config.sh

echo -e "${INFO_COLOR}Relaunching service ${DATA_COLOR}${SERVICE}${INFO_COLOR} at remote ${DATA_COLOR}${remoteHost}${INFO_COLOR} ..${NULL_COLOR}"

. _check-env.sh
. _prepare-relaunch.sh

if [ "${USE_IMAGE_DIGEST}" -eq 1 ]
then
	. _prepare-registry.sh
	. _prepare-digest.sh
fi

. _do-relaunch.sh

#!/bin/sh

. _definitions.sh

if [ "${#}" -lt "1" ]
then
	echo -e "${FAIL_COLOR}One network name (at least) must be provided by parameters!${NULL_COLOR}"
	exit 1
fi

. _ssh-config.sh

echo -e "\n${INFO_COLOR}Creating networks at remote ${DATA_COLOR}${remoteHost}${INFO_COLOR} ..${NULL_COLOR}\n"

. _check-env.sh

. _do-create-nets.sh

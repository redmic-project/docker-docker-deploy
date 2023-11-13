#!/bin/sh

. _definitions.sh

if [ "${#}" -lt "1" ]
then
	echo -e "${FAIL_COLOR}One network name (at least) must be provided by parameters!${NULL_COLOR}"
	exit 1
fi

. _ssh-config.sh

echo -e "\n${INFO_COLOR}Creating networks at remote ${DATA_COLOR}${remoteHost}${INFO_COLOR} ..${NULL_COLOR}\n"

createNetsCmd=""
for arg in "${@}"
do
	createNetsCmd="${createNetsCmd}\${createNetCmd} ${arg}; "
done
createNetsCmd="${createNetsCmd} :"

createNetsInRemoteCmd="\
	createNetCmd=\"docker network create\" && \
	if docker stack ls > /dev/null 2> /dev/null ; \
	then \
		createNetCmd=\"\${createNetCmd} -d overlay --attachable\" ; \
	fi ; \
	createNetsCmd=\$(echo \"${createNetsCmd}\") && \
	eval \"\${createNetsCmd}\""

if ssh ${SSH_PARAMS} "${SSH_REMOTE}" ${createNetsInRemoteCmd}
then
	echo -e "${PASS_COLOR}Network creation was successful!${NULL_COLOR}"
else
	echo -e "${FAIL_COLOR}Network creation failed!${NULL_COLOR}"
	eval "${closeSshCmd}"
	exit 1
fi

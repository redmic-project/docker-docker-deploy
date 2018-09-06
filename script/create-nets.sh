#!/bin/sh

. _definitions.sh

echo -e "\n${INFO_COLOR}Creating networks ..${NULL_COLOR}\n"

if [ "${#}" -lt "1" ]
then
	echo -e "${FAIL_COLOR}One network name (at least) must be provided by parameters!${NULL_COLOR}"
	exit 1
fi

. _ssh-config.sh

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

ssh ${SSH_PARAMS} "${SSH_REMOTE}" ${createNetsInRemoteCmd}

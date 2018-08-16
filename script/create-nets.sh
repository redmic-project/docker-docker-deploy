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
	docker stack ls > /dev/null 2> /dev/null ; \
	if [ \"\${?}\" -eq \"0\" ] ; \
	then \
		createNetCmd=\"\${createNetCmd} -d overlay --attachable\" ; \
	fi ; \
	createNetsCmd=\$(echo \"${createNetsCmd}\") && \
	eval \"\${createNetsCmd}\""

ssh ${SSH_PARAMS} "${SSH_REMOTE}" ${createNetsInRemoteCmd}

#!/bin/sh

. _definitions.sh

if [ -z "${SERVICE}" ]
then
	echo -e "${FAIL_COLOR}You must define 'SERVICE' in environment, with the name of service to relaunch${NULL_COLOR}"
	exit 1
fi

. _ssh-config.sh

echo -e "\n${INFO_COLOR}Relaunching service ${DATA_COLOR}${SERVICE}${INFO_COLOR} at remote ${DATA_COLOR}${remoteHost}${INFO_COLOR} ..${NULL_COLOR}"

relaunchCmd="\
	imageNameAndTag=\$(docker service ls -f 'name=${SERVICE}' --format '{{.Image}}' | head -1) && \
	imageName=\$(echo \${imageNameAndTag} | cut -f 1 -d ':' | cut -f 1 -d '@') && \
	if [ -z \"\${imageName}\" ] ; \
	then \
		echo -e \"${FAIL_COLOR}Service image not found!${NULL_COLOR}\" && \
		exit 1 ; \
	fi ; \
	if [ ! -z \"${REGISTRY_USER}\" ] ; \
	then \
		docker login -u \"${REGISTRY_USER}\" -p \"${REGISTRY_PASS}\" ${REGISTRY_URL} ; \
	fi ; \
	docker pull \${imageNameAndTag} && \
	imageDigest=\$(docker images --digests --format '{{.Digest}}' \${imageName} | head -1) && \
	docker service update -q --force --image \${imageName}@\${imageDigest} ${SERVICE}"

if ssh ${SSH_PARAMS} "${SSH_REMOTE}" "${relaunchCmd}"
then
	echo -e "${PASS_COLOR}Service ${DATA_COLOR}${SERVICE}${PASS_COLOR} relaunched!${NULL_COLOR}"
else
	echo -e "${FAIL_COLOR}Service ${DATA_COLOR}${SERVICE}${PASS_COLOR} relaunch failed!${NULL_COLOR}"
	ssh ${SSH_PARAMS} -q -O exit "${SSH_REMOTE}"
	exit 1
fi

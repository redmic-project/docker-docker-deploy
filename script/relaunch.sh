#!/bin/sh

. _definitions.sh

if [ -z "${SERVICE}" ]
then
	echo -e "${FAIL_COLOR}You must define 'SERVICE' in environment, with the name of service to relaunch${NULL_COLOR}"
	exit 1
fi

. _ssh-config.sh

echo -e "\n${INFO_COLOR}Relaunching service ${DATA_COLOR}${SERVICE}${INFO_COLOR} ..${NULL_COLOR}"

relaunchCmd="\
	imageNameAndTag=\$(docker service ls --filter 'name=${SERVICE}' --format '{{.Image}}') && \
	imageName=\$(echo \${imageNameAndTag} | cut -f 1 -d ':' | cut -f 1 -d '@') && \
	if [ -z \"\${imageName}\" ] ; \
	then \
		echo -e \"${FAIL_COLOR}Service image not found!${NULL_COLOR}\" && \
		exit 0 ; \
	fi ; \
	docker login -u ${REGISTRY_USER} -p ${CI_JOB_TOKEN} ${CI_REGISTRY} && \
	docker pull \${imageNameAndTag} && \
	imageDigest=\$(docker images --digests --format '{{.Digest}}' \${imageName} | head -1) && \
	docker service update --force --image \${imageName}@\${imageDigest} ${SERVICE} && \
	echo -e \"\\n${PASS_COLOR}Service ${DATA_COLOR}${SERVICE}${PASS_COLOR} relaunched!${NULL_COLOR}\" \
"

ssh ${SSH_PARAMS} "${SSH_REMOTE}" "${relaunchCmd}"

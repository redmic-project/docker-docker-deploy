#!/bin/sh

. _definitions.sh

if [ -z "${SERVICE}" ]
then
	echo -e "${FAIL_COLOR}You must define 'SERVICE' in environment, with the name of service to relaunch${NULL_COLOR}"
	exit 1
fi

. _ssh-config.sh

echo -e "\n${INFO_COLOR}Relaunching service ${DATA_COLOR}${SERVICE}${INFO_COLOR} at remote ${DATA_COLOR}${remoteHost}${INFO_COLOR} ..${NULL_COLOR}"

if [ "${USE_IMAGE_DIGEST}" -eq 1 ]
then
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
			echo \"${REGISTRY_PASS}\" | docker login -u \"${REGISTRY_USER}\" --password-stdin ${REGISTRY_URL} ; \
		fi ; \
		docker pull \${imageNameAndTag} && \
		imageDigest=\$(docker images --digests --format '{{.Digest}}' \${imageName} | head -1) && \
		docker service update -q --force --image \${imageName}@\${imageDigest} ${SERVICE}"
else
	relaunchCmd="docker service update -q --force ${SERVICE}"
fi

if runRemoteCmd "${relaunchCmd}"
then
	echo -e "${PASS_COLOR}Service ${DATA_COLOR}${SERVICE}${PASS_COLOR} relaunched successfully!${NULL_COLOR}"
else
	echo -e "${FAIL_COLOR}Service ${DATA_COLOR}${SERVICE}${FAIL_COLOR} relaunch failed!${NULL_COLOR}"
	eval "${closeSshCmd}"
	exit 1
fi

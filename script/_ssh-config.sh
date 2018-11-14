#!/bin/sh

. _definitions.sh

if [ -z "${SSH_REMOTE}" ]
then
	echo -e "${FAIL_COLOR}You must define 'SSH_REMOTE' in environment, with remote user and hostname (like 'ssh-user@ssh-remote')${NULL_COLOR}"
	exit 1
fi

remoteHost=$(echo "${SSH_REMOTE}" | cut -f 2 -d '@')

if [ -z "${GITLAB_DEPLOY_KEY}" ]
then
	echo -e "${FAIL_COLOR}You must define 'GITLAB_DEPLOY_KEY' in environment, with a SSH private key accepted by remote server${NULL_COLOR}"
	exit 1
fi

# Se prepara la identidad para conectar al servidor de despliegue.
ssh-agent -s
echo "${GITLAB_DEPLOY_KEY}" | tr -d '\r' | ssh-add - > /dev/null

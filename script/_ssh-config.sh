#!/bin/sh

if [ -z "${SSH_REMOTE}" ]
then
	echo -e "${FAIL_COLOR}You must define 'SSH_REMOTE' in environment${NULL_COLOR}"
	exit 1
fi

remoteUser=$(echo "${SSH_REMOTE}" | cut -d '@' -f 1)
remoteHost=$(echo "${SSH_REMOTE}" | cut -d '@' -f 2)

if [ -z "${remoteHost}" ]
then
	echo -e "${FAIL_COLOR}Remote host not found, define 'SSH_REMOTE' with remote user and hostname (like 'ssh-user@ssh-remote')${NULL_COLOR}"
	exit 1
fi

if [ -z "${DEPLOY_KEY}" ]
then
	echo -e "${FAIL_COLOR}You must define 'DEPLOY_KEY' in environment, with a SSH private key accepted by remote host${NULL_COLOR}"
	exit 1
fi

# Se prepara la identidad para conectar al servidor de despliegue.
eval "$(ssh-agent)" > /dev/null
echo "${DEPLOY_KEY}" | tr -d '\r' | ssh-add - > /dev/null 2>&1

# Prepara comando de cierre de sesión SSH.
closeSshCmd="ssh -l ${remoteUser} ${SSH_PARAMS} -q -O exit \"${remoteHost}\""

runRemoteCmd() {
	ssh -l ${remoteUser} ${SSH_PARAMS} "${remoteHost}" "${1}"
}

# Se comprueba si está disponible la conexión hacia el entorno donde se va a desplegar.
if ! runRemoteCmd ":" &> /dev/null
then
	echo -e "${FAIL_COLOR}Failed to connect to host ${DATA_COLOR}${remoteHost}${FAIL_COLOR} at port ${DATA_COLOR}${SSH_PORT}${FAIL_COLOR} with user ${DATA_COLOR}${remoteUser}${FAIL_COLOR}!${NULL_COLOR}"
	eval "${closeSshCmd}"
	exit 1
fi

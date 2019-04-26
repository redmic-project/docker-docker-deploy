#!/bin/sh

echo -e "\n${INFO_COLOR}Deploying at remote target ${DATA_COLOR}${remoteHost}${INFO_COLOR} ..${NULL_COLOR}\n"

deployCmd="\
	cd ${DEPLOY_HOME} && \
	if [ ! -z \"${REGISTRY_USER}\" ] ; \
	then \
		docker login -u \"${REGISTRY_USER}\" -p \"${REGISTRY_PASS}\" ${REGISTRY_URL} ; \
		deployAuthParam=\"--with-registry-auth\" ; \
	else \
		deployAuthParam=\"\" ; \
	fi ; \
	if docker stack ls > /dev/null 2> /dev/null ; \
	then \
		composeFileSplitted=\$(echo ${COMPOSE_FILE} | sed 's/:/ -c /g') && \
		env -i \$(${GREP_BIN} -v '^[#| ]' .env | xargs) \
			docker stack deploy -c \${composeFileSplitted} \${deployAuthParam} ${STACK:-${SERVICE}} ; \
	else \
		docker-compose stop ${SERVICE} && \
		docker-compose rm -f ${SERVICE} && \
		docker-compose pull ${SERVICE} && \
		docker-compose up -d ${SERVICE} ; \
	fi"

cleanDeployCmd="ssh ${SSH_PARAMS} \"${SSH_REMOTE}\" \"rm -rf ${DEPLOY_HOME}\""

if ssh ${SSH_PARAMS} "${SSH_REMOTE}" "${deployCmd}"
then
	echo -e "${PASS_COLOR}Services successfully deployed!${NULL_COLOR}"
	eval "${cleanDeployCmd}"
else
	echo -e "${FAIL_COLOR}Services deploy failed!${NULL_COLOR}"
	eval "${cleanDeployCmd}"
	ssh ${SSH_PARAMS} -q -O exit "${SSH_REMOTE}"
	exit 1
fi

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
	if [ ${FORCE_DOCKER_COMPOSE} -eq 0 ] && docker stack ls > /dev/null 2> /dev/null ; \
	then \
		composeFileSplitted=\$(echo ${COMPOSE_FILE} | sed 's/:/ -c /g') && \
		${GREP_BIN} -v '^[#| ]' .env | sed -r \"s/(\w+)=(.*)/export \1='\2'/g\" > .env-deploy && \
		env -i /bin/sh -c \". \$(pwd)/.env-deploy && \
			docker stack deploy -c \${composeFileSplitted} \${deployAuthParam} ${STACK}\" ; \
	else \
		composeCmd=\"docker-compose -p ${STACK}\" ; \
		\${composeCmd} stop && \
		\${composeCmd} rm -f && \
		\${composeCmd} pull && \
		\${composeCmd} up -d ; \
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

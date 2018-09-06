#!/bin/sh

echo -e "\n${INFO_COLOR}Deploying at remote target ..${NULL_COLOR}\n"

deployCmd="\
	cd ${DEPLOY_HOME} && \
	docker login -u ${REGISTRY_USER} -p ${CI_JOB_TOKEN} ${CI_REGISTRY} && \
	if docker stack ls > /dev/null 2> /dev/null ; \
	then \
		composeFileSplitted=\$(echo ${COMPOSE_FILE} | sed 's/:/ -c /g') && \
		env -i \$(grep -v '^#\\| ' .env | xargs) \
			docker stack deploy -c \${composeFileSplitted} --with-registry-auth ${STACK:-${SERVICE}} ; \
	else \
		docker-compose stop ${SERVICE} && \
		docker-compose rm -f ${SERVICE} && \
		docker-compose pull ${SERVICE} && \
		docker-compose up -d ${SERVICE} ; \
	fi ; \
	cd .. && \
	rm -rf ${DEPLOY_HOME}\
"

ssh ${SSH_PARAMS} "${SSH_REMOTE}" "${deployCmd}"

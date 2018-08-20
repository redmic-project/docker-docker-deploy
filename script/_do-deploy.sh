#!/bin/sh

echo -e "\n${INFO_COLOR}Deploying at remote target ..${NULL_COLOR}\n"

deployCmd="\
	cd ${DEPLOY_HOME} && \
	echo \"${CI_JOB_TOKEN}\" | docker login --username ${REGISTRY_USER} --password-stdin ${CI_REGISTRY} && \
	docker stack ls > /dev/null 2> /dev/null ; \
	if [ \"\${?}\" -ne \"0\" ] ; \
	then \
		docker-compose stop ${SERVICE} && \
		docker-compose rm -f ${SERVICE} && \
		docker-compose pull ${SERVICE} && \
		docker-compose up -d ${SERVICE} && \
		rm ${DEFAULT_DEPLOY_FILES} ; \
	else \
		composeFileSplitted=\$(echo ${COMPOSE_FILE} | sed 's/:/ -c /g') && \
		env -i \$(grep -v '^#\\| ' .env | xargs) \
			docker stack deploy -c \${composeFileSplitted} --with-registry-auth ${STACK:-${SERVICE}} && \
		rm ${DEFAULT_DEPLOY_FILES} ; \
	fi\
"

ssh ${SSH_PARAMS} "${SSH_REMOTE}" "${deployCmd}"

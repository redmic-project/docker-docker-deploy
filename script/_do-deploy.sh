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
	standardComposeFileSplitted=\$(echo ${COMPOSE_FILE} | sed 's/:/ -f /g') ; \
	if [ ${FORCE_DOCKER_COMPOSE} -eq 0 ] && docker stack ls > /dev/null 2> /dev/null ; \
	then \
		swarmComposeFileSplitted=\$(echo ${COMPOSE_FILE} | sed 's/:/ -c /g') && \
		${GREP_BIN} -v '^[#| ]' .env | sed -r \"s/(\w+)=(.*)/export \1='\2'/g\" > .env-deploy && \
		env -i /bin/sh -c \". \$(pwd)/.env-deploy && \
			docker stack deploy \${deployAuthParam} --resolve-image ${SWARM_RESOLVE_IMAGE} -c \${swarmComposeFileSplitted} ${STACK}\" && \
		if [ ! -z \"\${deployAuthParam}\" ] ; \
		then \
			servicesToAuth=\"${SERVICES_TO_AUTH}\" && \
			if [ -z \"\${servicesToAuth}\" ] ; \
			then \
				if [ ${DOCKER_23_COMPATIBLE_TARGET} -eq 0 ] ; \
				then \
					servicesToAuth=\"\$(docker --log-level error compose -f \${standardComposeFileSplitted} config --services | sed \"s/^/${STACK}_/g\")\" ; \
				else \
					servicesToAuth=\"\$(docker-compose --log-level ERROR -f \${standardComposeFileSplitted} config --services | sed \"s/^/${STACK}_/g\")\" ; \
				fi ; \
			fi && \
			if [ ! -z \"\${servicesToAuth}\" ] ; \
			then \
				for serviceToAuth in \${servicesToAuth} ; \
				do \
					docker service update -d \${deployAuthParam} \${serviceToAuth} ; \
				done ; \
			fi ; \
		fi ; \
	else \
		if [ ${DOCKER_23_COMPATIBLE_TARGET} -eq 0 ] ; \
		then \
			composeCmd=\"docker compose -f \${standardComposeFileSplitted} -p ${STACK}\" ; \
		else \
			composeCmd=\"docker-compose -f \${standardComposeFileSplitted} -p ${STACK}\" ; \
		fi && \
		\${composeCmd} stop ${SERVICES_TO_DEPLOY} && \
		\${composeCmd} rm -f ${SERVICES_TO_DEPLOY} && \
		\${composeCmd} pull ${SERVICES_TO_DEPLOY} && \
		\${composeCmd} up -d ${SERVICES_TO_DEPLOY} ; \
	fi"

cleanDeployCmd="ssh ${SSH_PARAMS} \"${SSH_REMOTE}\" \"rm -rf ${DEPLOY_HOME}\""

if ssh ${SSH_PARAMS} "${SSH_REMOTE}" "${deployCmd}"
then
	echo -e "${PASS_COLOR}Services successfully deployed!${NULL_COLOR}"
	if [ ${OMIT_CLEAN_DEPLOY} -eq 0 ]
	then
		eval "${cleanDeployCmd}"
	else
		echo -e "${INFO_COLOR}Deployment resources cleaning omitted${NULL_COLOR}"
	fi
else
	echo -e "${FAIL_COLOR}Services deployment failed!${NULL_COLOR}"
	eval "${cleanDeployCmd}"
	ssh ${SSH_PARAMS} -q -O exit "${SSH_REMOTE}"
	exit 1
fi

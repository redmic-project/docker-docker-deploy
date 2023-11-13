#!/bin/sh

echo -e "\n${INFO_COLOR}Deploying at host ${DATA_COLOR}${remoteHost}${INFO_COLOR} ..${NULL_COLOR}\n"

if [ ${deployingToSwarm} -ne 0 ]
then
	if [ ${docker23CompatibleTarget} -eq 0 ]
	then
		composeBaseCmd="docker compose"
	else
		composeBaseCmd="docker-compose"
	fi
fi

deployCmd="\
	cd ${deployHome} && \
	if [ ! -z \"${REGISTRY_USER}\" ] ; \
	then \
		docker login -u \"${REGISTRY_USER}\" -p \"${REGISTRY_PASS}\" ${REGISTRY_URL} ; \
		deployAuthParam=\"--with-registry-auth\" ; \
	else \
		deployAuthParam=\"\" ; \
	fi ; \
	if [ ${deployingToSwarm} -eq 0 ] ; \
	then \
		swarmComposeFileSplitted=\$(echo ${COMPOSE_FILE} | sed 's/:/ -c /g') && \
		${GREP_BIN} -v '^[#| ]' .env | sed -r \"s/(\w+)=(.*)/export \1='\2'/g\" > .env-deploy && \
		env -i /bin/sh -c \". \$(pwd)/.env-deploy && \
			docker stack deploy \${deployAuthParam} --resolve-image ${SWARM_RESOLVE_IMAGE} -c \${swarmComposeFileSplitted} ${STACK}\" && \
		if [ ! -z \"\${deployAuthParam}\" ] ; \
		then \
			servicesToAuth=\"${SERVICES_TO_AUTH:-${servicesInComposeFiles}}\" && \
			if [ ! -z \"\${servicesToAuth}\" ] ; \
			then \
				for serviceToAuth in \${servicesToAuth} ; \
				do \
					docker service update -d \${deployAuthParam} \${serviceToAuth} ; \
				done ; \
			fi ; \
		fi ; \
	else \
		COMPOSE_FILE=\"${COMPOSE_FILE}\" ; \
		composeCmd=\"${composeBaseCmd} -p ${STACK}\" ; \
		\${composeCmd} stop ${SERVICES_TO_DEPLOY} && \
		\${composeCmd} rm -f ${SERVICES_TO_DEPLOY} && \
		\${composeCmd} pull ${SERVICES_TO_DEPLOY} && \
		\${composeCmd} up -d ${SERVICES_TO_DEPLOY} ; \
	fi"

cleanDeployCmd="ssh ${SSH_PARAMS} \"${SSH_REMOTE}\" \"rm -rf ${deployHome}\""

if ssh ${SSH_PARAMS} "${SSH_REMOTE}" "${deployCmd}"
then
	echo -e "\n${PASS_COLOR}Services successfully deployed!${NULL_COLOR}"
	if [ ${OMIT_CLEAN_DEPLOY} -eq 0 ]
	then
		eval "${cleanDeployCmd}"
	else
		echo -e "${INFO_COLOR}Deployment resources cleaning omitted${NULL_COLOR}"
	fi
else
	echo -e "\n${FAIL_COLOR}Services deployment failed!${NULL_COLOR}"
	eval "${cleanDeployCmd}"
	eval "${closeSshCmd}"
	exit 1
fi

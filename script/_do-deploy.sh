#!/bin/sh

moveToDeployDirCmd="cd ${deployHome} && "

if [ ! -z "${REGISTRY_USER}" ]
then
	echo -e "\n${INFO_COLOR}Login to registry ${DATA_COLOR}${REGISTRY_URL:-<default>}${INFO_COLOR} ..${NULL_COLOR}\n"

	loginCmd="\
		${GREP_BIN} \"^${ddRegistryPassVarName}=\" \"${COMPOSE_ENV_FILE_NAME}\" | cut -d '=' -f 2- | tr -d \"'\" | \
		docker login -u \"${REGISTRY_USER}\" --password-stdin ${REGISTRY_URL}"

	if runRemoteCmd "${moveToDeployDirCmd}${loginCmd}"
	then
		echo -e "\n${PASS_COLOR}Login to registry was successful!${NULL_COLOR}"
	else
		echo -e "\n${FAIL_COLOR}Login to registry failed!${NULL_COLOR}"
	fi

	deployAuthParam="--with-registry-auth"
else
	echo -e "\n${INFO_COLOR}Omitting login to registry${NULL_COLOR}"
fi

if [ ${deployingToSwarm} -eq 0 ]
then
	deploySwarmCmd="\
		${GREP_BIN} -v '^[#| ]' \"${COMPOSE_ENV_FILE_NAME}\" | \
			sed -r \"s/(\w+)=(.*)/export \1='\2'/g\" > .env-deploy && \
		env -i /bin/sh -c \"\
			. \$(pwd)/.env-deploy && \
			rm .env-deploy && \
			docker stack deploy \
				${deployAuthParam} \
				--resolve-image ${SWARM_RESOLVE_IMAGE} \
				-c ${swarmComposeFileSplitted} \
				${STACK}\""

	if [ ! -z "${deployAuthParam}" ]
	then
		servicesToAuth="${SERVICES_TO_AUTH:-${servicesInComposeFiles}}"

		if [ ! -z "${servicesToAuth}" ]
		then
			if [ "${SWARM_RESOLVE_IMAGE}" = "never" ]
			then
				updateResolveParam="--no-resolve-image"
			fi

			updateForAuthCmd="\
				for serviceToAuth in ${servicesToAuth} ; \
				do \
					docker service update -d \
						${deployAuthParam} \
						${updateResolveParam} \
						\${serviceToAuth} ; \
				done"
		fi
	fi

	deployCmd="${moveToDeployDirCmd}${deploySwarmCmd}${updateForAuthCmd:+ && }${updateForAuthCmd}"
else
	composeCmd="\
		${composeBaseCmd} \
			-f ${standardComposeFileSplitted} \
			--env-file \"${COMPOSE_ENV_FILE_NAME}\" \
			-p ${STACK}"

	deployComposeCmd="\
		${composeCmd} stop ${SERVICES_TO_DEPLOY} && \
		${composeCmd} rm -f ${SERVICES_TO_DEPLOY} && \
		${composeCmd} pull ${SERVICES_TO_DEPLOY} && \
		${composeCmd} up -d ${SERVICES_TO_DEPLOY}"

	deployCmd="${moveToDeployDirCmd}${deployComposeCmd}"
fi

echo -e "\n${INFO_COLOR}Deploying at host ${DATA_COLOR}${remoteHost}${INFO_COLOR} ..${NULL_COLOR}\n"

runRemoteCmd "${deployCmd}"
deployExitCode=${?}

if [ "${OMIT_CLEAN_DEPLOY}" -eq 0 ]
then
	cleanDeployCmd="rm -r ${deployHome}"
	runRemoteCmd "${cleanDeployCmd}"
else
	echo -e "\n${INFO_COLOR}Deployment resources cleaning omitted${NULL_COLOR}"
fi

if [ ${deployExitCode} -eq 0 ]
then
	echo -e "\n${PASS_COLOR}Services successfully deployed!${NULL_COLOR}"
else
	echo -e "\n${FAIL_COLOR}Services deployment failed!${NULL_COLOR}"
	eval "${closeSshCmd}"
	exit 1
fi

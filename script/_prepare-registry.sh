#!/bin/sh

# Si existen credenciales para registry, se usan de manera segura.
if [ ! -z "${REGISTRY_USER}" ]
then
	serviceUpdateAdditionalArgs="${serviceUpdateAdditionalArgs} --with-registry-auth"

	echo -e "${INFO_COLOR}Login to registry ${DATA_COLOR}${REGISTRY_URL:-<default>}${INFO_COLOR} ..${NULL_COLOR}\n"

	# Se prepara la ruta de trabajo.
	randomValue="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)"
	relaunchHome="${DEPLOY_PATH}/docker-deploy/${randomValue}"
	createDirCmd="mkdir -p ${relaunchHome}"

	if ! runRemoteCmd "${createDirCmd}"
	then
		echo -e "${FAIL_COLOR}Relaunch path ${DATA_COLOR}${relaunchHome}${FAIL_COLOR} creation failed!${NULL_COLOR}"
		eval "${closeSshCmd}"
		exit 1
	fi

	# Se preparan las credenciales de forma segura.
	relaunchEnvFile=".env-relaunch"
	ddRegistryPassVarName=DOCKER_DEPLOY_REGISTRY_PASS
	moveToRelaunchDirCmd="cd ${relaunchHome} && "

	echo -e "${ddRegistryPassVarName}=${REGISTRY_PASS}" > "${relaunchEnvFile}"

	echo -e "${INFO_COLOR}Sending relaunch resources to host ${DATA_COLOR}${remoteHost}${INFO_COLOR} ..${NULL_COLOR}"
	echo -e "  ${INFO_COLOR}relaunch path [ ${DATA_COLOR}${relaunchHome}${INFO_COLOR} ]${NULL_COLOR}"

	scp ${SSH_PARAMS} "${relaunchEnvFile}" "${SSH_REMOTE}:${relaunchHome}"
	sendResourcesExitCode=${?}

	rm "${relaunchEnvFile}"

	if [ "${sendResourcesExitCode}" -eq 0 ]
	then
		echo -e "\n${PASS_COLOR}Relaunch resources successfully sent!${NULL_COLOR}\n"
	else
		echo -e "\n${FAIL_COLOR}Relaunch resources sending failed!${NULL_COLOR}"
		eval "${closeSshCmd}"
		exit 1
	fi

	# Se realiza la identificación en el registry.
	loginCmd="\
		${GREP_BIN} \"^${ddRegistryPassVarName}=\" \"${relaunchEnvFile}\" | cut -d '=' -f 2- | \
		docker login -u \"${REGISTRY_USER}\" --password-stdin ${REGISTRY_URL}"

	if runRemoteCmd "${moveToRelaunchDirCmd}${loginCmd}"
	then
		echo -e "\n${PASS_COLOR}Login to registry was successful!${NULL_COLOR}"
	else
		echo -e "\n${FAIL_COLOR}Login to registry failed!${NULL_COLOR}"
	fi

	# Se limpia la ruta de trabajo.
	cleanRelaunchCmd="rm -r ${relaunchHome}"
	runRemoteCmd "${cleanRelaunchCmd}"
else
	echo -e "${INFO_COLOR}Omitting login to registry${NULL_COLOR}"
fi

#!/bin/sh

SERVICES_TO_CHECK="${SERVICES_TO_CHECK:-${STACK:-${SERVICE}}}"

echo -e "\n${INFO_COLOR}Checking deployment of services [${NULL_COLOR} ${SERVICES_TO_CHECK} ${INFO_COLOR}] ..${NULL_COLOR}\n"

for serviceToCheck in ${SERVICES_TO_CHECK}
do
	echo -e "${INFO_COLOR}Checking deployment of service ${NULL_COLOR}${serviceToCheck}${INFO_COLOR} ..${NULL_COLOR}"
	echo -e "  ${INFO_COLOR}retries ${NULL_COLOR}${STATUS_CHECK_RETRIES}${INFO_COLOR}, interval ${NULL_COLOR}${STATUS_CHECK_INTERVAL}${INFO_COLOR}s, hits ${NULL_COLOR}${STATUS_CHECK_MIN_HITS}\n"

	checkDeployCmd="\
		docker stack ls > /dev/null 2> /dev/null ; \
		if [ \"\${?}\" -eq \"0\" ] ; \
		then \
			SWARM_MODE=true ; \
		fi ; \
		hits=0 && \
		for i in \$(seq 1 ${STATUS_CHECK_RETRIES}) ; \
		do \
			echo -e \"  try \${i}/${STATUS_CHECK_RETRIES} .. \\c\" && \
			if [ \"\${SWARM_MODE}\" = true ] ; \
			then \
				stackServices=\$(docker service ls -f name=${serviceToCheck} --format '{{.Replicas}}') ; \
				serviceCount=\$(echo \"\${stackServices}\" | /usr/bin/grep -cE '.+') ; \
				runningServiceCount=\$(echo \"\${stackServices}\" | /usr/bin/grep -cE '([0-9]+)\/\1') ; \
				statusCheckCmd=\"[ \"\${serviceCount}\" -ne \"0\" -a \
					\"\${serviceCount:-_}\" = \"\${runningServiceCount:--}\" ]\" ; \
			else \
				runningContainersIds=\$(docker ps -f status=running --format '{{.ID}}' --no-trunc) ; \
				successfullyExitedContainersIds=\$(docker ps -a -f exited=0 --format '{{.ID}}' --no-trunc) ; \
				serviceContainerId=\$(docker inspect --format='{{.ID}}' ${serviceToCheck} 2> /dev/null) ; \
				runningService=\$(echo \"\${runningContainersIds}\" | grep \"\${serviceContainerId:--}\") ; \
				successfullyExitedService=\$(echo \"\${successfullyExitedContainersIds}\" | \
					grep \"\${serviceContainerId:--}\") ; \
				statusCheckCmd=\"[ \${serviceContainerId:-_} = \${runningService:--} -o \
					\${serviceContainerId:-_} = \${successfullyExitedService:--} ]\" ; \
			fi ; \
			eval \"\${statusCheckCmd}\" ; \
			if [ \"\${?}\" -eq \"0\" ] ; \
			then \
				echo -e \"${PASS_COLOR}[PASS]${NULL_COLOR}\" && \
				hits=\$((\${hits} + 1)) && \
				if [ \"\${hits}\" -eq \"${STATUS_CHECK_MIN_HITS}\" ] ; \
				then \
					echo -e \"\\n${PASS_COLOR}Service ${NULL_COLOR}${serviceToCheck}${PASS_COLOR} is running!${NULL_COLOR}\" && \
					echo -e \"  got ${PASS_COLOR}\${hits}/${STATUS_CHECK_MIN_HITS}${NULL_COLOR} status hits\" && \
					exit 0 ; \
				fi ; \
			else \
				echo -e \"${FAIL_COLOR}[FAIL]${NULL_COLOR}\" ; \
			fi ; \
			sleep ${STATUS_CHECK_INTERVAL} ; \
		done ; \
		echo -e \"\\n${FAIL_COLOR}Service ${NULL_COLOR}${serviceToCheck}${PASS_COLOR} is not running!${NULL_COLOR}\" && \
		echo -e \"  got ${FAIL_COLOR}\${hits}/${STATUS_CHECK_MIN_HITS}${NULL_COLOR} status hits\" && \
		exit 1 \
	"

	ssh ${SSH_PARAMS} "${SSH_REMOTE}" "${checkDeployCmd}"
done

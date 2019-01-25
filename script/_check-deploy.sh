#!/bin/sh

SERVICES_TO_CHECK="${SERVICES_TO_CHECK:-${STACK:-${SERVICE}}}"
GREP_BIN="${GREP_BIN:-grep}"

echo -e "\n${INFO_COLOR}Checking deployment of services [${DATA_COLOR} ${SERVICES_TO_CHECK} ${INFO_COLOR}] at ${DATA_COLOR}${remoteHost}${INFO_COLOR} ..${NULL_COLOR}"

for serviceToCheck in ${SERVICES_TO_CHECK}
do
	echo -e "\n${INFO_COLOR}Checking deployment of service ${DATA_COLOR}${serviceToCheck}${INFO_COLOR} ..${NULL_COLOR}"
	echo -e "  ${INFO_COLOR}retries ${DATA_COLOR}${STATUS_CHECK_RETRIES}${INFO_COLOR}, interval ${DATA_COLOR}${STATUS_CHECK_INTERVAL}${INFO_COLOR}s, hits ${DATA_COLOR}${STATUS_CHECK_MIN_HITS}${NULL_COLOR}\n"

	checkDeployCmd="\
		hits=0 && \
		for i in \$(seq 1 ${STATUS_CHECK_RETRIES}) ; \
		do \
			echo -e \"  try \${i}/${STATUS_CHECK_RETRIES} .. \\c\" && \
			if docker stack ls > /dev/null 2> /dev/null ; \
			then \
				stackServices=\$(docker service ls -f name=${serviceToCheck} --format '{{.Replicas}}') ; \
				serviceCount=\$(echo \"\${stackServices}\" | ${GREP_BIN} -cE '.+') ; \
				runningServiceCount=\$(echo \"\${stackServices}\" | ${GREP_BIN} -cE '([0-9]+)\/\1') ; \
				for j in \$(seq 1 \${serviceCount}) ; \
				do \
					runningServiceName=\$(docker service ls -f name=${serviceToCheck} --format '{{.Name}}' | \
						head -\${j} | tail -1) ; \
					runningServiceDesiredReplicas=\$(docker service ls -f name=\${runningServiceName} \
						--format '{{.Replicas}}' | cut -d '/' -f 2) ; \
					completedTaskCount=0 ; \
					for k in \$(seq 1 \${runningServiceDesiredReplicas}) ; \
					do \
						runningServiceStoppedTaskState=\$(docker service ps --format '{{.CurrentState}}' \
							-f 'desired-state=shutdown' -f \"name=\${runningServiceName}.\${k}\" \
							\${runningServiceName} | head -1) ; \
						if echo \"\${runningServiceStoppedTaskState}\" | grep 'Complete' > /dev/null 2> /dev/null ; \
						then \
							completedTaskCount=\$((\${completedTaskCount} + 1)) ; \
						fi ; \
					done ; \
					if [ \${completedTaskCount} -eq \${runningServiceDesiredReplicas} ] ; \
					then \
						runningServiceCount=\$((\${runningServiceCount} + 1)) ; \
					fi ; \
				done ; \
				statusCheckCmd=\"[ \"\${serviceCount}\" -ne \"0\" -a \
					\"\${serviceCount:-_}\" = \"\${runningServiceCount:--}\" ]\" ; \
			else \
				runningContainersIds=\$(docker ps -f status=running --format '{{.ID}}' --no-trunc) ; \
				successfullyExitedContainersIds=\$(docker ps -a -f exited=0 --format '{{.ID}}' --no-trunc) ; \
				serviceContainerId=\$(docker inspect --format='{{.ID}}' ${serviceToCheck} 2> /dev/null) ; \
				runningService=\$(echo \"\${runningContainersIds}\" | ${GREP_BIN} \"\${serviceContainerId:--}\") ; \
				successfullyExitedService=\$(echo \"\${successfullyExitedContainersIds}\" | \
					${GREP_BIN} \"\${serviceContainerId:--}\") ; \
				statusCheckCmd=\"[ \${serviceContainerId:-_} = \${runningService:--} -o \
					\${serviceContainerId:-_} = \${successfullyExitedService:--} ]\" ; \
			fi ; \
			if \${statusCheckCmd} ; \
			then \
				echo -e \"${PASS_COLOR}[PASS]${NULL_COLOR}\" && \
				hits=\$((\${hits} + 1)) && \
				if [ \"\${hits}\" -eq \"${STATUS_CHECK_MIN_HITS}\" ] ; \
				then \
					echo -e \"${PASS_COLOR}Service ${DATA_COLOR}${serviceToCheck}${PASS_COLOR} is running!${NULL_COLOR}\" && \
					echo -e \"  got ${PASS_COLOR}\${hits}/${STATUS_CHECK_MIN_HITS}${NULL_COLOR} status hits\" && \
					exit 0 ; \
				fi ; \
			else \
				echo -e \"${FAIL_COLOR}[FAIL]${NULL_COLOR}\" ; \
			fi ; \
			sleep ${STATUS_CHECK_INTERVAL} ; \
		done ; \
		echo -e \"${FAIL_COLOR}Service ${DATA_COLOR}${serviceToCheck}${FAIL_COLOR} is not running!${NULL_COLOR}\" && \
		echo -e \"  got ${FAIL_COLOR}\${hits}/${STATUS_CHECK_MIN_HITS}${NULL_COLOR} status hits\" && \
		exit 1"

	ssh ${SSH_PARAMS} "${SSH_REMOTE}" "${checkDeployCmd}"
done

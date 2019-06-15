#!/bin/sh

SERVICES_TO_CHECK="${SERVICES_TO_CHECK:-${STACK}}"

echo -e "\n${INFO_COLOR}Checking deployment of services [${DATA_COLOR} ${SERVICES_TO_CHECK} ${INFO_COLOR}] at ${DATA_COLOR}${remoteHost}${INFO_COLOR} ..${NULL_COLOR}"

checkDeployCmd="\
	success='' ; \
	for serviceToCheck in ${SERVICES_TO_CHECK} ; \
	do \
		echo -e \"\\n${INFO_COLOR}Checking deployment of service ${DATA_COLOR}\${serviceToCheck}${INFO_COLOR} ..${NULL_COLOR}\" ; \
		echo -e \"  ${INFO_COLOR}retries ${DATA_COLOR}${STATUS_CHECK_RETRIES}${INFO_COLOR}, interval ${DATA_COLOR}${STATUS_CHECK_INTERVAL}${INFO_COLOR}s, hits ${DATA_COLOR}${STATUS_CHECK_MIN_HITS}${NULL_COLOR}\\n\" ; \
		hits=0 && \
		for i in \$(seq 1 ${STATUS_CHECK_RETRIES}) ; \
		do \
			if docker stack ls > /dev/null 2> /dev/null ; \
			then \
				stackServices=\$(docker service ls -f name=\${serviceToCheck} --format '{{.Replicas}}') ; \
				serviceToCheckReplication=\$(echo \"\${stackServices}\" | head -1) ; \
				runningServiceName=\$(docker service ls -f name=\${serviceToCheck} --format '{{.Name}}' | head -1) ; \
				serviceCount=\$(echo \"\${stackServices}\" | ${GREP_BIN} -cE '.+') ; \
				if [ \${serviceCount} -gt 1 -a \${i} -eq 1 ] ; \
				then \
					echo -e \"${FAIL_COLOR}Found ${DATA_COLOR}\${serviceCount}${FAIL_COLOR} services filtering by name ${DATA_COLOR}\${serviceToCheck}${FAIL_COLOR},${NULL_COLOR}\" ; \
					echo -e \"  ${FAIL_COLOR}will check only the service exactly named ${DATA_COLOR}\${runningServiceName}${NULL_COLOR}\\n\" ; \
				fi ; \
				if [ \${serviceCount} -eq 0 ] ; \
				then \
					if [ \${i} -eq 1 ] ; \
					then \
						echo -e \"${FAIL_COLOR}Cannot find running service by name ${DATA_COLOR}\${serviceToCheck}${NULL_COLOR}\\n\" ; \
					fi ; \
					serviceIsRunning=\"[ 0 -ne 0 ]\" ; \
					success=\"\${success} 0\" ; \
					break ; \
				else \
					runningServiceCount=\$(echo \"\${serviceToCheckReplication}\" | ${GREP_BIN} -cE '([0-9]+)\/\1') ; \
					serviceIsRunning=\"[ \${runningServiceCount} -eq 1 ]\" ; \
					if ! \${serviceIsRunning} ; \
					then \
						serviceToCheckDesiredReplicas=\$(echo \${serviceToCheckReplication} | cut -d '/' -f 2) ; \
						completedTaskCount=0 ; \
						for j in \$(seq 1 \${serviceToCheckDesiredReplicas}) ; \
						do \
							replicaStoppedTaskState=\$(docker service ps --format '{{.CurrentState}}' \
								-f 'desired-state=shutdown' -f \"name=\${runningServiceName}.\${j}\" \
								\${runningServiceName} | head -1) ; \
							if echo \"\${replicaStoppedTaskState}\" | ${GREP_BIN} 'Complete' > /dev/null 2> /dev/null ; \
							then \
								completedTaskCount=\$((\${completedTaskCount} + 1)) ; \
							fi ; \
						done ; \
						if [ \${completedTaskCount} -eq \${serviceToCheckDesiredReplicas} ] ; \
						then \
							serviceIsRunning=true ; \
						fi ; \
					fi ; \
				fi ; \
				statusCheckCmd=\${serviceIsRunning} ; \
			else \
				runningContainersIds=\$(docker ps -f status=running --format '{{.ID}}' --no-trunc) ; \
				successfullyExitedContainersIds=\$(docker ps -a -f exited=0 --format '{{.ID}}' --no-trunc) ; \
				serviceContainerId=\$(docker inspect --format='{{.ID}}' \${serviceToCheck} 2> /dev/null) ; \
				runningService=\$(echo \"\${runningContainersIds}\" | ${GREP_BIN} \"\${serviceContainerId:--}\") ; \
				successfullyExitedService=\$(echo \"\${successfullyExitedContainersIds}\" | \
					${GREP_BIN} \"\${serviceContainerId:--}\") ; \
				statusCheckCmd=\"[ \${serviceContainerId:-_} = \${runningService:--} -o \
					\${serviceContainerId:-_} = \${successfullyExitedService:--} ]\" ; \
			fi ; \
			echo -e \"  try \${i}/${STATUS_CHECK_RETRIES} .. \\c\" ; \
			if \${statusCheckCmd} ; \
			then \
				echo -e \"${PASS_COLOR}[PASS]${NULL_COLOR}\" && \
				hits=\$((\${hits} + 1)) && \
				if [ \"\${hits}\" -eq \"${STATUS_CHECK_MIN_HITS}\" ] ; \
				then \
					echo -e \"\\n${PASS_COLOR}Service ${DATA_COLOR}\${serviceToCheck}${PASS_COLOR} is running!${NULL_COLOR}\" && \
					echo -e \"  got ${PASS_COLOR}\${hits}/${STATUS_CHECK_MIN_HITS}${NULL_COLOR} status hits\" && \
					success=\"\${success} 1\" ; \
					break ; \
				fi ; \
				if [ \"\${i}\" -eq \"${STATUS_CHECK_RETRIES}\" ] ; \
				then \
					success=\"\${success} 0\" ; \
					break ; \
				fi ; \
			else \
				echo -e \"${FAIL_COLOR}[FAIL]${NULL_COLOR}\" ; \
				if [ \"\${i}\" -eq \"${STATUS_CHECK_RETRIES}\" ] ; \
				then \
					echo -e \"\\n${FAIL_COLOR}Service ${DATA_COLOR}\${serviceToCheck}${FAIL_COLOR} is not running!${NULL_COLOR}\" && \
					echo -e \"  got ${FAIL_COLOR}\${hits}/${STATUS_CHECK_MIN_HITS}${NULL_COLOR} status hits\" && \
					success=\"\${success} 0\" ; \
					break ; \
				fi ; \
			fi ; \
			sleep ${STATUS_CHECK_INTERVAL} ; \
		done ; \
	done ; \
	for serviceSuccess in \${success[*]} ; \
	do \
		if [ \${serviceSuccess} -eq 0 ] ; \
		then \
			exit 1 ; \
		fi ; \
	done"

if ssh ${SSH_PARAMS} "${SSH_REMOTE}" "${checkDeployCmd}"
then
	echo -e "\\n${PASS_COLOR}All services seems ok!${NULL_COLOR}"
else
	echo -e "\\n${FAIL_COLOR}One or more services seems failed!${NULL_COLOR}"
	ssh ${SSH_PARAMS} -q -O exit "${SSH_REMOTE}"
	exit 1
fi

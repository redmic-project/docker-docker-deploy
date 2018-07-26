#!/bin/sh

checkDeployCmd="\
	docker stack ls > /dev/null 2> /dev/null ; \
	if [ \"\${?}\" -eq \"0\" ]; \
	then \
		SWARM_MODE=true ; \
	fi ; \
	hits=0 && \
	for i in \$(seq 1 ${STATUS_CHECK_RETRIES}) ; \
	do \
		echo \"Checking service status, try \${i}/${STATUS_CHECK_RETRIES} ...\" && \
		if [ \"\${SWARM_MODE}\" = true ]; \
		then \
			stackServices=\$(docker service ls -f name=${SERVICE} --format '{{.Replicas}}') ; \
			serviceCount=\$(echo \"\${stackServices}\" | /usr/bin/grep -cE '.+') ; \
			runningServiceCount=\$(echo \"\${stackServices}\" | /usr/bin/grep -cE '([0-9]+)\/\1') ; \
			statusCheckCmd=\"[ \"\${serviceCount}\" -ne \"0\" -a \"\${serviceCount:-_}\" = \"\${runningServiceCount:--}\" ]\" ; \
		else \
			runningContainersIds=\$(docker ps -f status=running --format '{{.ID}}' --no-trunc) ; \
			successfullyExitedContainersIds=\$(docker ps -a -f exited=0 --format '{{.ID}}' --no-trunc) ; \
			serviceContainerId=\$(docker inspect --format='{{.ID}}' ${SERVICE} 2> /dev/null) ; \
			runningService=\$(echo \"\${runningContainersIds}\" | grep \"\${serviceContainerId:--}\") ; \
			successfullyExitedService=\$(echo \"\${successfullyExitedContainersIds}\" | grep \"\${serviceContainerId:--}\") ; \
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
				echo -e \"Service is running, got ${PASS_COLOR}\${hits}/${STATUS_CHECK_MIN_HITS}${NULL_COLOR} status hits\" && \
				exit 0 ; \
			fi ; \
		else \
			echo -e \"${FAIL_COLOR}[FAIL]${NULL_COLOR}\" ; \
		fi ; \
		sleep ${STATUS_CHECK_INTERVAL} ; \
	done ; \
	echo -e \"Service is not running, got ${FAIL_COLOR}\${hits}/${STATUS_CHECK_MIN_HITS}${NULL_COLOR} status hits\" && \
	exit 1 \
"
ssh ${SSH_PARAMS} "${SSH_REMOTE}" "${checkDeployCmd}"

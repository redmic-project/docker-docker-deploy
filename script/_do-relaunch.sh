#!/bin/sh

relaunchCmd="docker service update -q --force \
	${serviceUpdateAdditionalArgs} \
	${serviceToRelaunch}"

if runRemoteCmd "${relaunchCmd}"
then
	echo -e "\n${PASS_COLOR}Service ${DATA_COLOR}${serviceToRelaunch}${PASS_COLOR} relaunched successfully!${NULL_COLOR}"
else
	echo -e "\n${FAIL_COLOR}Service ${DATA_COLOR}${serviceToRelaunch}${FAIL_COLOR} relaunch failed!${NULL_COLOR}"
	eval "${closeSshCmd}"
	exit 1
fi

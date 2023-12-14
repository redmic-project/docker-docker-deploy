#!/bin/sh

# Prepara comando base de creación de red
createNetCmd="docker network create"
if [ ${deployingToSwarm} -eq 0 ]
then
	createNetCmd="${createNetCmd} -d overlay --attachable"
fi

# Prepara comando compuesto de creación de redes
createNetsCmd=":"
for netName in "${@}"
do
	createNetsCmd="${createNetCmd} ${netName}; ${createNetsCmd}"
done

if runRemoteCmd "${createNetsCmd}"
then
	echo -e "${PASS_COLOR}Networks creation was successful!${NULL_COLOR}"
else
	echo -e "${FAIL_COLOR}Networks creation failed!${NULL_COLOR}"
	eval "${closeSshCmd}"
	exit 1
fi

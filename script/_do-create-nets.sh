#!/bin/sh

# Prepara comando base de creación de red
createNetCmd="docker network create"
if [ ${deployingToSwarm} -eq 0 ]
then
	createNetCmd="${createNetCmd} -d overlay --attachable"
fi

echo -e "  ${INFO_COLOR}command [ ${DATA_COLOR}${createNetCmd}${INFO_COLOR} ]${NULL_COLOR}\n"

# Prepara comando compuesto de creación de redes
createNetsCmd=":"
for netName in "${@}"
do
	createNetsCmd="${createNetCmd} ${netName} && ${createNetsCmd}"
done

if runRemoteCmd "${createNetsCmd}"
then
	echo -e "\n${PASS_COLOR}Networks creation was successful!${NULL_COLOR}"
else
	echo -e "\n${FAIL_COLOR}Networks creation failed!${NULL_COLOR}"
	eval "${closeSshCmd}"
	exit 1
fi

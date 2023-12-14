#!/bin/sh

echo -e "\n${INFO_COLOR}Using digest data to obtain updated image for relaunch ..${NULL_COLOR}"

getServiceImageCmd="docker service ls -f 'name=${serviceToRelaunch}' --format '{{.Image}}' | cut -d '@' -f 1"
serviceImageNameAndTag=$(runRemoteCmd "${getServiceImageCmd}")

if [ -z "${serviceImageNameAndTag}" ]
then
	echo -e "\n${FAIL_COLOR}Service image not found, needed to relaunch service using image digest!${NULL_COLOR}"
	eval "${closeSshCmd}"
	exit 1
fi

# Se obtiene la imagen actualizada.
getUpdatedServiceImageCmd="docker pull ${serviceImageNameAndTag}"

if runRemoteCmd "${getUpdatedServiceImageCmd}"
then
	echo -e "\n${PASS_COLOR}Image updated successfully!${NULL_COLOR}"
else
	echo -e "\n${FAIL_COLOR}Image update failed!${NULL_COLOR}"
fi

serviceImageName=$(echo "${serviceImageNameAndTag}" | cut -d ':' -f 1)

# Se obtiene el valor de digest de la imagen actualizada.
getServiceImageDigestCmd="docker images --digests --format '{{.Digest}}' ${serviceImageName})"
serviceImageDigest=$(runRemoteCmd "${getServiceImageDigestCmd}")

# Prepara variable usada desde el script principal
serviceUpdateAdditionalArgs="${serviceUpdateAdditionalArgs} --image ${serviceImageName}@${serviceImageDigest}"

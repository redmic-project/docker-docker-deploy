ARG DOCKER_COMPOSE_VERSION=1.24.0
FROM docker/compose:${DOCKER_COMPOSE_VERSION}

LABEL maintainer="info@redmic.es"

ARG OPENSSH_CLIENT_VERSION=7.7_p1-r4
RUN apk --update --no-cache add \
	openssh-client=${OPENSSH_CLIENT_VERSION}

COPY script/ /script/
RUN \
	binPath=/usr/bin; \
	for filePath in /script/*; \
	do \
		fileName=$(basename "${filePath}"); \
		chmod 755 "${filePath}"; \
		ln -s "${filePath}" "${binPath}/${fileName}"; \
		ln -s "${filePath}" "${binPath}/${fileName%.*}"; \
	done

ENTRYPOINT ["/bin/sh", "-c"]

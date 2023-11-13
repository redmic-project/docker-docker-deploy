ARG DOCKER_VERSION
FROM docker:${DOCKER_VERSION}

LABEL maintainer="info@redmic.es"

ARG OPENSSH_VERSION
RUN apk --update --no-cache add \
	openssh-client-default=${OPENSSH_VERSION}

COPY script/ /script/
RUN \
	binPath=/usr/bin; \
	for filePath in /script/*; \
	do \
		fileName=$(basename "${filePath}"); \
		ln -s "${filePath}" "${binPath}/${fileName}"; \
		ln -s "${filePath}" "${binPath}/${fileName%.*}"; \
	done

ENTRYPOINT ["/bin/sh", "-c"]

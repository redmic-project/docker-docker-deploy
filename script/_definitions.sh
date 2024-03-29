#!/bin/sh

ENV_PREFIX="${ENV_PREFIX:-DD_}"
ENV_SPACE_REPLACEMENT="${ENV_SPACE_REPLACEMENT:-<dd-space>}"
COMPOSE_FILE="${COMPOSE_FILE:-compose.yaml}"
COMPOSE_ENV_FILE_NAME="${COMPOSE_ENV_FILE_NAME:-.env}"
DEPLOY_PATH="${DEPLOY_PATH:-~}"
DEPLOY_DIR_NAME="${DEPLOY_DIR_NAME:-deploy}"
DEFAULT_DEPLOY_FILES="${DEFAULT_DEPLOY_FILES:-*compose*.y*ml ${COMPOSE_ENV_FILE_NAME}}"
FORCE_DOCKER_COMPOSE="${FORCE_DOCKER_COMPOSE:-0}"
OMIT_CLEAN_DEPLOY="${OMIT_CLEAN_DEPLOY:-0}"
SWARM_RESOLVE_IMAGE="${SWARM_RESOLVE_IMAGE:-always}"
ALLOW_COMPOSE_ENV_FILE_INTERPOLATION="${ALLOW_COMPOSE_ENV_FILE_INTERPOLATION:-0}"
OMIT_WAITING_TO_CONVERGE="${OMIT_WAITING_TO_CONVERGE:-0}"

OMIT_STATUS_CHECK="${OMIT_STATUS_CHECK:-0}"
STATUS_CHECK_RETRIES="${STATUS_CHECK_RETRIES:-10}"
STATUS_CHECK_INTERVAL="${STATUS_CHECK_INTERVAL:-20}"
STATUS_CHECK_DELAY="${STATUS_CHECK_DELAY:-120}"
STATUS_CHECK_MIN_HITS="${STATUS_CHECK_MIN_HITS:-3}"
USE_IMAGE_DIGEST="${USE_IMAGE_DIGEST:-0}"

GREP_BIN="${GREP_BIN:-grep}"
SSH_PORT="${SSH_PORT:-22}"
SSH_CONTROL_PERSIST="${SSH_CONTROL_PERSIST:-10}"

INFO_COLOR='\033[1;36m'
DATA_COLOR='\033[1;33m'
FAIL_COLOR='\033[0;31m'
PASS_COLOR='\033[0;32m'
NULL_COLOR='\033[0m'

SSH_PARAMS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=error \
	-o "ControlPath=\"/ssh_connection_socket_%h_%p_%r\"" -o ControlMaster=auto \
	-o ControlPersist=${SSH_CONTROL_PERSIST} -o Port=${SSH_PORT} -o ConnectTimeout=10 -o BatchMode=yes"

version=$(cat /version)
echo -e "${INFO_COLOR}*** Docker deploy [ ${DATA_COLOR}${version}${INFO_COLOR} ] ***${NULL_COLOR}\n"

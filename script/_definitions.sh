#!/bin/sh

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"
DEPLOY_PATH="${DEPLOY_PATH:-~}"
DEPLOY_DIR_NAME="${DEPLOY_DIR_NAME:-deploy}"
DEFAULT_DEPLOY_FILES="${DEFAULT_DEPLOY_FILES:-docker-compose*.yml .env}"

STATUS_CHECK_RETRIES="${STATUS_CHECK_RETRIES:-10}"
STATUS_CHECK_INTERVAL="${STATUS_CHECK_INTERVAL:-20}"
STATUS_CHECK_DELAY="${STATUS_CHECK_DELAY:-120}"
STATUS_CHECK_MIN_HITS="${STATUS_CHECK_MIN_HITS:-3}"

GREP_BIN="${GREP_BIN:-grep}"
SSH_CONTROL_PERSIST="${SSH_CONTROL_PERSIST:-10}"

INFO_COLOR='\033[1;36m'
DATA_COLOR='\033[1;33m'
FAIL_COLOR='\033[0;31m'
PASS_COLOR='\033[0;32m'
NULL_COLOR='\033[0m'

SSH_PARAMS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=error \
	-o "ControlPath=\"/ssh_connection_socket_%h_%p_%r\"" -o ControlMaster=auto \
	-o ControlPersist=${SSH_CONTROL_PERSIST}"

SCRIPTS_PATH="/usr/bin/"

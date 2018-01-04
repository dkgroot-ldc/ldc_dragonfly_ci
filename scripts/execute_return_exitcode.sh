#!/usr/bin/env bash
#
# Terminate immediately on any failure
# Echo the exit code in readable form as the last line
# This EXIT_CODE can then be processed on the other end of the ssh connection, to capture the original exit code
#
# Created by: Diederik de Groot (2018)

trap 'echo -n SSH_REMOTE_EXIT_CODE=$?' INT TERM EXIT
set -e
$@

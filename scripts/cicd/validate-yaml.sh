#!/bin/bash

# script to run YAML validation in CI environment to avoid pitfalls of running in inconsitent environments

# Bash safeties: exit on error, pipelines can't hide errors
set -o errexit
set -o pipefail

# get the directory of this script
SCRIPT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# if defined, run with the docker image passed in RUN_WITH_DOCKER_IMAGE
if [[ -n "${RUN_WITH_DOCKER_IMAGE}" ]] ; then
    docker run \
        --volume /var/run/docker.sock:/var/run/docker.sock \
        --volume "$PWD:$PWD" \
        --workdir "$PWD" \
        --user $(id -u):$(id -g) \
        --env VALIDATE_YAML_KUBEVAL \
        --env VALIDATE_YAML_NOMOS \
        ${RUN_WITH_DOCKER_IMAGE} \
        bash ${SCRIPT_ROOT}/../kpt/hydrate.sh
else
    export RUN_KPT_CLI_WITH_DOCKER='true'
    bash ${SCRIPT_ROOT}/../kpt/hydrate.sh
fi

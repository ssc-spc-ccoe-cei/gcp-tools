#!/bin/bash

# script to run YAML validation in CI environment

# Bash safeties: exit on error, pipelines can't hide errors
set -o errexit
set -o pipefail

# get the directory of this script
# SCRIPT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# for future use
# if RUN_WITH_DOCKER is true, run with the docker image passed in DOCKER_IMAGE
# TODO: set default image if DOCKER_IMAGE not defined
if [[ "${RUN_WITH_DOCKER}" == "true" ]] ; then
    docker run \
        --volume /var/run/docker.sock:/var/run/docker.sock \
        --volume $PWD:/workspace \
        --workdir /workspace \
        --user $(id -u):$(id -g) \
        --env VALIDATE_YAML_KUBEVAL \
        --env VALIDATE_YAML_NOMOS \
        ${DOCKER_IMAGE} \
        bash tools/scripts/kpt/hydrate.sh
else
    # kpt is not installed on pipeline runners, set this flag to run kpt CLI with its docker image
    export RUN_KPT_CLI_WITH_DOCKER='true'
    bash tools/scripts/kpt/hydrate.sh
fi

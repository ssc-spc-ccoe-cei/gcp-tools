#!/bin/bash

# script to run YAML validation in CI environment
# it may eventually be used to run and control different validations (hydrate, unit test, gatekeeper, etc.)

# Bash safeties: exit on error, pipelines can't hide errors
set -o errexit
set -o pipefail

bash tools/scripts/kpt/hydrate.sh


# ###### for future use if using dev container ######
# # if RUN_WITH_DOCKER is true, run with the docker image passed in DOCKER_IMAGE
# # TODO: set default image if DOCKER_IMAGE not defined
# if [[ "${RUN_WITH_DOCKER}" == "true" ]] ; then
#     docker run \
#         --volume /var/run/docker.sock:/var/run/docker.sock \
#         --volume $PWD:/workspace \
#         --workdir /workspace \
#         --user $(id -u):$(id -g) \
#         --env VALIDATE_YAML_KUBEVAL \
#         --env VALIDATE_YAML_NOMOS \
#         ${DOCKER_IMAGE} \
#         bash tools/scripts/kpt/hydrate.sh
# else
#     bash tools/scripts/kpt/hydrate.sh
# fi

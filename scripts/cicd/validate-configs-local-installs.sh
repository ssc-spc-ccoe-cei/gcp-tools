#!/bin/bash

# Bash safeties: exit on error, pipelines can't hide errors
set -o errexit
set -o pipefail

KPT_VERSION='v1.0.0-beta.27'
NOMOS_IMAGE='gcr.io/config-management-release/nomos:v1.14.2'

# get the directory of this script
SCRIPT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# source print-colors.sh for better readability of the script's outputs
source "${SCRIPT_ROOT}/../common/print-colors.sh"
source "${SCRIPT_ROOT}/../common/repo-directories.sh"

install_kpt() {
    echo "Checking if kpt is installed ..."
    if [[ "v$(kpt version)" == "${KPT_VERSION}" ]] ; then
        echo "kpt version '$(kpt version)' is already installed."
    else
        echo "Installing kpt ..."
        curl -LSso kpt_linux_amd64 "https://github.com/GoogleContainerTools/kpt/releases/download/${KPT_VERSION}/kpt_linux_amd64"
        chmod +x kpt_linux_amd64
        mv kpt_linux_amd64 /usr/local/bin/kpt
        echo "kpt version '$(kpt version)' is now installed."
    fi
}

install_nomos() {
    # echo "Checking if nomos is installed ..."
    # if gcloud version | grep nomos ; then
    #     echo "nomos version '$(gcloud version | grep nomos)' is already installed."
    # else
    #     echo "Installing nomos ..."
    #     # none of the 3 options work
    #     # gcloud components install nomos

    #     # sudo apt-get install google-cloud-sdk-nomos

    #     # gsutil cp gs://config-management-release/released/1.14.2/linux_amd64/nomos nomos
    #     # chmod +x nomos
    #     # mv nomos /usr/local/bin/nomos

    #     #echo "nomos version '$(gcloud version | grep nomos)' is now installed."
    # fi
    echo "Checking if nomos image is pulled ..."
    if [[ "$(docker image list ${NOMOS_IMAGE} --quiet)" != "" ]] ; then
        echo "docker image '${NOMOS_IMAGE}' is already pulled."
    else
        echo "Pulling nomos docker image ..."
        docker image pull ${NOMOS_IMAGE} --quiet
        echo "nomos image is pulled."
    fi
}

# function to run each validation if environment variable is defined
validate_in_directory() {
    
    if [ -d "${1}" ]; then
        dir_to_validate="${1}"
    else
        print_error "Invalid directory passed as argument: '${1}'"
        exit 1
    fi

    print_divider "Starting validation in directory '${dir_to_validate}'"

    if [[ "${VALIDATE_SCHEMA_NOMOS}" == "true" ]] ; then
        install_nomos
        echo "Validating YAML schema with 'nomos vet'"
        docker run --volume "$PWD/${dir_to_validate}:/${dir_to_validate}" ${NOMOS_IMAGE} vet --no-api-server-check --source-format unstructured --path "/${dir_to_validate}"
        print_success "'nomos vet' was successful."
    fi

    if [[ "${VALIDATE_SCHEMA_KUBEVAL}" == "true" ]] ; then
        install_kpt
        echo "Validating YAML schema with 'kubeval'"
        kpt fn eval -i kubeval:v0.3.0 "${dir_to_validate}" --truncate-output=false -- ignore_missing_schemas=true strict=true
        print_success "'kubeval' was successful."
    fi

}

# check if argument is a valid directory
if [ -d "${1}" ]; then
    validate_in_directory "${1}"
else
    echo "Directory not passed as argument, will default to 'DEPLOY_DIR/<ENV_SUBDIRS>' ..."
    for en in ${ENV_SUBDIRS}
    do
        # check if folder exists
        if [ -d "${DEPLOY_DIR}/${en}" ]; then
            validate_in_directory "${DEPLOY_DIR}/${en}"
        else
            echo "'${DEPLOY_DIR}/${en}' does not exists, skipping."
        fi
    done

# TODO: make sure the validate_in_directory ran at least once?
# else
#     print_error "Invalid directory passed as argument: '${1}'"
#     exit 1
fi


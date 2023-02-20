#!/bin/bash

# script to hydrate and validate kpt packages
# inspired from gitops blueprint, but hydrated files are in a separate folder instead of separate repo
# this allows for reviewing source files and hydrated files in a single Pull Request
# https://github.com/GoogleCloudPlatform/blueprints/blob/main/catalog/gitops/hydration-trigger.yaml

# TODO: add better error handling/trapping
set -eo pipefail

# the script is meant to run from the root of the deployment git repo
# the directories defined here are relative to that directory
DEPLOY_DIR="deploy"
SOURCE_BASE_DIR="source-base"
SOURCE_CUSTOMIZATION_DIR="source-customization"
TEMP_DIR="temp-workspace"

# get the directory of this script
SCRIPT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# source print-colors.sh for better readability of the script's outputs
source "${SCRIPT_ROOT}/../common/print-colors.sh"

# ensure the working directory is set to the root of the deployment git repo
cd "${SCRIPT_ROOT}/../../.."

exit_code=0

function hydrate-env () {
    print_info "running function: 'hydrate-env ${1}'"
    # test that an environment was passed
    if [ -z "${1}" ]; then
        print_warning "missing environment, exiting function."
        return
    fi
    environment=${1}
    env_temp_subdir="${TEMP_DIR}/${environment}"
    env_deploy_dir="${DEPLOY_DIR}/${environment}"

    # the hydrated output folder must not exist, remove the entire temp sub-folder in case it exists and create a customized folder
    rm -rf "${env_temp_subdir}"
    mkdir -p "${env_temp_subdir}/customized"

    # copy source base to temp customized folder and apply customization
    # check if source-customization/env is empty (assumes it contains at least '.gitkeep'), don't copy base if customization is empty
    if [ $(ls -A ${SOURCE_CUSTOMIZATION_DIR}/${environment} | wc --lines) -gt 1 ]; then
        echo "Copying '${SOURCE_BASE_DIR}/.' to '${env_temp_subdir}/customized' ..."
        cp -rf "${SOURCE_BASE_DIR}/." "${env_temp_subdir}/customized"
    else
        echo "'${SOURCE_CUSTOMIZATION_DIR}/${environment}' is empty, skipping '${SOURCE_BASE_DIR}' copy."
    fi
    
    echo "Copying '${SOURCE_CUSTOMIZATION_DIR}/${environment}/.' over '${env_temp_subdir}/customized' ..."
    cp -rf "${SOURCE_CUSTOMIZATION_DIR}/${environment}/." "${env_temp_subdir}/customized/."
    
    # initialize the customized directory as a top level kpt package
    echo -e "\nInitializing kpt in '${env_temp_subdir}/customized' ..."
    kpt pkg init "${env_temp_subdir}/customized"

    # render in temp directory because some resources, like ResourceHierarchy don't remove yaml files when there is an edit/delete
    # render to execute kpt functions defined in Kptfile pipeline
    # setting a different output folder ensures only proper YAML files are kept (it will remove README.md, etc.)
    print_info "Running 'kpt fn render ${env_temp_subdir}/customized' --output=${env_temp_subdir}/hydrated' ..."
    kpt fn render "${env_temp_subdir}/customized" --output="${env_temp_subdir}/hydrated" --truncate-output=false

    # remove local configuration files (resources having a `local-config` annotation)
    # this cleans up resources which are not meant to be deployed (setters.yaml, etc.)
    print_info "Removing local kpt configurations ..."
    kpt fn eval "${env_temp_subdir}/hydrated" --image="gcr.io/kpt-fn/remove-local-config-resources:v0.1" --truncate-output=false

    # re-add .gitkeep to handle empty folders (if all resources are removed)
    touch "${env_temp_subdir}/hydrated/.gitkeep"

    # check for rendered changes
    if git diff --no-index --quiet --exit-code "${env_deploy_dir}" "${env_temp_subdir}/hydrated"; then 
        print_info "No changes detected for rendered resources."
        true
    else
        print_warning "Change detected, copying '${env_temp_subdir}/hydrated' to '${env_deploy_dir}' ..."
        rm -rf "${env_deploy_dir}"
        cp -r "${env_temp_subdir}/hydrated" "${env_deploy_dir}"
        # set exit code to 1 to make sure the pre-commit or pipeline fails
        exit_code=1
        # print the git status, could be commented out if too verbose
        git status
    fi
    # cleanup (these are part of gitignore, but delete anyways)
    # rm -rf "${env_temp_subdir}"

    # # list resources to be applied (could maybe run this on the diff, if any?)
    # echo "listing resources that will be deployed..."
    # kpt pkg tree "${env_deploy_dir}"

    # map deploy directory to docker then run nomos vet from image
    # volume mapping need absolute path
    print_info "Running 'nomos vet' on ${env_deploy_dir} ..."
    docker run -v "$PWD/${env_deploy_dir}:/${env_deploy_dir}" gcr.io/config-management-release/nomos:v1.14.0-rc.1 nomos vet --no-api-server-check --source-format unstructured --path "/${env_deploy_dir}"

    print_success "function 'hydrate-env ${1}' finished successfully."
}

# check if source directories are valid
if [ ! -d "${SOURCE_BASE_DIR}" ]; then
    print_error "invalid SOURCE_BASE_DIR: ${SOURCE_BASE_DIR}"
    exit 1
fi
if [ ! -d "${SOURCE_CUSTOMIZATION_DIR}" ]; then
    print_error "invalid SOURCE_CUSTOMIZATION_DIR: ${SOURCE_CUSTOMIZATION_DIR}"
    exit 1
fi

# TODO: handle test folder, it should only run the hydration (not the validation againts the deploy folder)
# the hydrate-env function might need to be broken down into separate functions...

# TODO: possible enhancement, loop on $(ls ${SOURCE_CUSTOMIZATION_DIR}) and validate folder names instead of hardcoded loop with skips

for en in experimentation dev preprod prod
do
    # check if env. folder exists in source-customization
    if [ -d "${SOURCE_CUSTOMIZATION_DIR}/${en}" ]; then
        hydrate-env "${en}"
    else
        print_info "'${SOURCE_CUSTOMIZATION_DIR}/${en}' does not exists, skipping."
    fi
done

if [ ${exit_code} -ne 0 ]; then
    print_warning "The script detected change in configurations and will fail (for pre-commit and pipeline purposes)."
    echo "This may be normal if you've run it locally for the first time after making changes to 'soure-base' and/or 'source-customization'"
    echo "If you see this message in a pre-commit hook: re-run git add, git commit and push the changes."
    echo "If you see this message in a PR pipeline: you might need to re-run 'bash tools/scripts/kpt/hydrate.sh' locally and push the changes."
else
    print_success "Hydration is complete and validated."
fi

exit $exit_code

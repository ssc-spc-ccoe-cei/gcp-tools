#!/bin/bash

# script to hydrate and validate kpt packages
# inspired from gitops blueprint, but hydrated files are in a separate folder instead of separate repo
# this allows for reviewing source files and hydrated files in a single Pull Request
# https://github.com/GoogleCloudPlatform/blueprints/blob/main/catalog/gitops/hydration-trigger.yaml

# some of the script's execution can be controlled with environment variables.
#   VALIDATE_SETTERS_CUSTOMIZATION: set to 'false' to disable the check for setters customization
#   VALIDATE_YAML_KUBEVAL: set to 'false' to disable the YAML file validation with kubeval
#   VALIDATE_YAML_NOMOS: set to 'false' to disable the YAML file validation with nomos

# TODO: add better error handling/trapping
# Bash safeties: exit on error, pipelines can't hide errors
set -o errexit
set -o pipefail

# pin kpt and nomos versions
KPT_VERSION='v1.0.0-beta.21'
NOMOS_VERSION='v1.14.2'

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

# check if directories are valid
if [ ! -d "${DEPLOY_DIR}" ]; then
    print_error "invalid DEPLOY_DIR: ${DEPLOY_DIR}"
    exit 1
fi
if [ ! -d "${SOURCE_BASE_DIR}" ]; then
    print_error "invalid SOURCE_BASE_DIR: ${SOURCE_BASE_DIR}"
    exit 1
fi
if [ ! -d "${SOURCE_CUSTOMIZATION_DIR}" ]; then
    print_error "invalid SOURCE_CUSTOMIZATION_DIR: ${SOURCE_CUSTOMIZATION_DIR}"
    exit 1
fi
if ! grep "^${TEMP_DIR}/" .gitignore >/dev/null 2>&1 ; then
    print_error "TEMP_DIR/ is not in '.gitignore': ${TEMP_DIR}"
    exit 1
fi

# run kpt CLI with docker image when not installed (it is not installed on pipeline runners)
if [[ "v$(kpt version)" == "${KPT_VERSION}" ]] ; then
    echo "kpt CLI version '$(kpt version)' is installed and will be used."
    KPT="kpt"
else
    KPT="docker run --volume /var/run/docker.sock:/var/run/docker.sock --volume $PWD:/workspace --workdir /workspace --user $(id -u):$(id -g) gcr.io/kpt-dev/kpt:${KPT_VERSION}"
    echo "kpt will run with docker image: ${KPT}"
fi

# initialize exit code variable, to keep track of failures while continuing the script executions
exit_code=0

function hydrate-env () {
    print_divider "Running function: 'hydrate-env ${1}'"
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
    if [ $(ls -A "${SOURCE_CUSTOMIZATION_DIR}/${environment}" | wc --lines) -gt 1 ]; then
        echo "Copying '${SOURCE_BASE_DIR}/.' to '${env_temp_subdir}/customized' ..."
        cp -rf "${SOURCE_BASE_DIR}/." "${env_temp_subdir}/customized"

        # check that each setters file in the source base folder are in the customization folder
        if [[ "${VALIDATE_SETTERS_CUSTOMIZATION}" != "false" ]] ; then
            echo "Validating that all 'setters*.yaml' files exist in '${SOURCE_CUSTOMIZATION_DIR}/${environment}' ..."
            for setters_file in $(find ${SOURCE_BASE_DIR} -name "setters*.yaml" | cut --delimiter '/' --fields 2-)
            do
                if [ ! -f "${SOURCE_CUSTOMIZATION_DIR}/${environment}/${setters_file}" ]; then
                    print_error "Missing customization: ${SOURCE_CUSTOMIZATION_DIR}/${environment}/${setters_file}"
                    exit 1
                fi
                # TODO: possible enhancement, maybe check if there is a diff?
            done
        else
            echo "Skipping setters customization validation."
        fi
    else
        echo "'${SOURCE_CUSTOMIZATION_DIR}/${environment}' is empty, skipping '${SOURCE_BASE_DIR}' copy."
    fi

    echo "Copying '${SOURCE_CUSTOMIZATION_DIR}/${environment}/.' over '${env_temp_subdir}/customized' ..."
    cp -rf "${SOURCE_CUSTOMIZATION_DIR}/${environment}/." "${env_temp_subdir}/customized/."

    # initialize the customized directory as a top level kpt package
    echo -e "\nInitializing kpt in '${env_temp_subdir}/customized' ..."
    ${KPT} pkg init "${env_temp_subdir}/customized"

    # render in temp directory because some resources, like ResourceHierarchy don't remove yaml files when there is an edit/delete
    # render to execute kpt functions defined in Kptfile pipeline
    # setting a different output folder ensures only proper YAML files are kept (it will remove README.md, etc.)
    print_info "Running 'kpt fn render ${env_temp_subdir}/customized' --output=${env_temp_subdir}/hydrated' ..."
    ${KPT} fn render "${env_temp_subdir}/customized" --output="${env_temp_subdir}/hydrated" --truncate-output=false

    # remove local configuration files (resources having a `local-config` annotation)
    # this cleans up resources which are not meant to be deployed (setters.yaml, etc.)
    print_info "Removing local kpt configurations ..."
    ${KPT} fn eval "${env_temp_subdir}/hydrated" --image="gcr.io/kpt-fn/remove-local-config-resources:v0.1" --truncate-output=false

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

    validate_yaml_in_dir "${env_deploy_dir}"

    print_success "function 'hydrate-env ${1}' finished successfully."
}

# function to run validation in a given directory, if environment variable is defined
validate_yaml_in_dir() {

    if [ -d "${1}" ]; then
        dir_to_validate="${1}"
    else
        print_error "Invalid directory passed as argument: '${1}'"
        exit 1
    fi

    print_info "Starting validation in directory '${dir_to_validate}'"

    # defaults to always run, unless environment variable flags are set to false
    # TODO: possibly handle validation exit codes to separate from other failures

    if [[ "${VALIDATE_YAML_KUBEVAL}" != "false" ]] ; then
        echo "Validating YAML files with 'kubeval' ..."
        # whether it's by design or not, kubeval can change quotes in annotations and remove duplicate resources (maybe 'kpt fn eval' does this?)
        # to workaround this, set an '--output' directory to avoid in-place modifications, the directory must not exist
        rm -rf "${TEMP_DIR}/kubeval/${dir_to_validate}"
        ${KPT} fn eval -i kubeval:v0.3.0 "${dir_to_validate}" --output="${TEMP_DIR}/kubeval/${dir_to_validate}" --truncate-output=false -- ignore_missing_schemas=true strict=true
        print_success "'kubeval' was successful."
    else
        echo "Skipping YAML validation with 'kubeval'."
    fi

    if [[ "${VALIDATE_YAML_NOMOS}" != "false" ]] ; then
        echo "Validating YAML files with 'nomos vet' ..."
        # check if nomos CLI is installed
        if nomos help >/dev/null 2>&1 ; then
            echo "Running nomos with locally installed CLI."
            nomos vet --no-api-server-check --source-format unstructured --path "${dir_to_validate}"
        else
            echo "Running nomos with docker image: ${NOMOS}"
            docker run --volume "$PWD:/workspace" \
                --workdir /workspace \
                gcr.io/config-management-release/nomos:${NOMOS_VERSION} \
                vet --no-api-server-check --source-format unstructured --path "${dir_to_validate}"
        fi
        print_success "'nomos vet' was successful."
    else
        echo "Skipping YAML validation with 'nomos'."
    fi
}

# TODO: handle test folder, it should only run the hydration (not the validation againts the deploy folder)
# the hydrate-env function might need to be broken down into separate functions...

# TODO: possible enhancement, loop on $(ls ${SOURCE_CUSTOMIZATION_DIR}) and validate folder names instead of hardcoded loop with skips

for env_subdir in experimentation dev preprod prod
do
    # check if env. folder exists in source-customization
    if [ -d "${SOURCE_CUSTOMIZATION_DIR}/${env_subdir}" ]; then
        hydrate-env "${env_subdir}"
    else
        echo "'${SOURCE_CUSTOMIZATION_DIR}/${env_subdir}' does not exists, skipping."
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

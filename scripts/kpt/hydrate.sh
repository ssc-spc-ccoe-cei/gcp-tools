#!/bin/bash

# script to hydrate and validate kpt packages
# inspired from gitops blueprint, but hydrated files are in a separate folder instead of separate repo
# this allows for reviewing source files and hydrated files in a single Pull Request
# https://github.com/GoogleCloudPlatform/blueprints/blob/main/catalog/gitops/hydration-trigger.yaml

# some of the script's execution can be controlled with environment variables.
#   VALIDATE_SETTERS_CUSTOMIZATION: set to 'false' to disable the check for setters customization
#   VALIDATE_YAML_KUBEVAL: set to 'false' to disable the YAML file validation with kubeval
#   VALIDATE_YAML_NOMOS: set to 'false' to disable the YAML file validation with nomos

# Bash safeties: exit on error, pipelines can't hide errors
set -o errexit
set -o pipefail

# pin kpt and nomos versions
KPT_VERSION='v1.0.0-beta.21'
NOMOS_VERSION='v1.14.2'

# the standard directory structure for processing customization and hydration
DEPLOY_DIR="deploy"
SOURCE_BASE_DIR="source-base"
SOURCE_CUSTOMIZATION_DIR="source-customization"
TEMP_DIR="temp-workspace"

# declare variable and array to store unique directories to process, will be used to associate statuses
dir_id=""
declare -a processed_dir_list

# declare associative arrays (-A) to store return/status codes of each directory id
declare -A status_render_diff
declare -A status_validate_setters
declare -A status_validate_kubeval
declare -A status_validate_nomos
declare -A status_kpt

# get the directory of this script
SCRIPT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# source print-colors.sh for better readability of the script's outputs
# shellcheck source-path=scripts/kpt # tell shellcheck where to look
source "${SCRIPT_ROOT}/../common/print-colors.sh"

# ensure the working directory is set to the root of the deployment git repo
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "${REPO_ROOT}"

# initialize exit code variable, to keep track of failures while continuing the script executions
error_counter=0
warning_counter=0
diff_counter=0
exit_code=0

# trap unhandled errors and unexpected termination
trap 'status=$?; echo "Script terminating unexpectedly with exit code: $status"; exit $status' INT TERM ERR

################################  FUNCTIONS  ################################

hydrate-env () {
    print_divider "Running 'hydrate-env' function for '${dir_id}'"
    # test that an environment was passed
    if [ -z "${1}" ]; then
        print_warning "missing environment, exiting function."
        warning_counter=$(expr ${warning_counter} + 1)
        return
    fi

    # run kpt CLI with docker image when not installed (it is not installed on pipeline runners)
    if [[ "v$(kpt version)" == "${KPT_VERSION}" ]] ; then
        echo "kpt CLI version '$(kpt version)' is installed and will be used."
        KPT="kpt"
    else
        KPT="docker run --volume /var/run/docker.sock:/var/run/docker.sock --volume $PWD:/workspace --workdir /workspace --user $(id -u):$(id -g) gcr.io/kpt-dev/kpt:${KPT_VERSION}"
        echo "kpt will run with docker image: ${KPT}"
    fi

    # save the directory id before processing it
    processed_dir_list+=("${dir_id}")

    environment=${1}
    env_temp_subdir="${TEMP_DIR}/${environment}"
    env_deploy_dir="${DEPLOY_DIR}/${environment}"

    # the hydrated output folder must not exist, remove the entire temp sub-folder in case it exists and create a customized folder
    rm -rf "${env_temp_subdir}"
    mkdir -p "${env_temp_subdir}/customized"

    # copy source base to temp customized folder and apply customization
    # check if source-customization/env is empty (assumes it contains at least '.gitkeep'), don't copy base if customization is empty
    # shellcheck disable=SC2012,SC2046 # disable 'use find instead of ls' and quoting suggestion
    if [ $(ls -A "${SOURCE_CUSTOMIZATION_DIR}/${environment}" | wc --lines) -gt 1 ]; then
        echo "Copying '${SOURCE_BASE_DIR}/.' to '${env_temp_subdir}/customized' ..."
        cp -rf "${SOURCE_BASE_DIR}/." "${env_temp_subdir}/customized"

        # check that each setters file in the source base folder are in the customization folder
        if [[ "${VALIDATE_SETTERS_CUSTOMIZATION}" != "false" ]] ; then
            echo "Validating that all 'setters*.yaml' files exist in '${SOURCE_CUSTOMIZATION_DIR}/${environment}' ..."
            # initialize status and update if failure is detected
            status_validate_setters["${dir_id}"]=0
            for setters_file in $(find ${SOURCE_BASE_DIR} -name "setters*.yaml" | cut --delimiter '/' --fields 2-)
            do
                if [ ! -f "${SOURCE_CUSTOMIZATION_DIR}/${environment}/${setters_file}" ]; then
                    print_error "Missing customization: ${SOURCE_CUSTOMIZATION_DIR}/${environment}/${setters_file}"
                    error_counter=$(expr ${error_counter} + 1)
                    status_validate_setters["${dir_id}"]=1
                    return
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
    if ${KPT} pkg init "${env_temp_subdir}/customized"
    then
        status_kpt["${dir_id}"]=0
    else
        print_error "'kpt pkg init' failed."
        error_counter=$(expr ${error_counter} + 1)
        status_kpt["${dir_id}"]=1
        return
    fi

    # render in temp directory because some resources, like ResourceHierarchy don't remove yaml files when there is an edit/delete
    # render to execute kpt functions defined in Kptfile pipeline
    # setting a different output folder ensures only proper YAML files are kept (it will remove README.md, etc.)
    print_info "Running 'kpt fn render ${env_temp_subdir}/customized' --output=${env_temp_subdir}/hydrated' ..."
    if ${KPT} fn render "${env_temp_subdir}/customized" --output="${env_temp_subdir}/hydrated" --truncate-output=false
    then
        status_kpt["${dir_id}"]=0
    else
        print_error "'kpt fn render' failed."
        error_counter=$(expr ${error_counter} + 1)
        status_kpt["${dir_id}"]=1
        return
    fi

    # remove local configuration files (resources having a `local-config` annotation)
    # this cleans up resources which are not meant to be deployed (setters.yaml, etc.)
    print_info "Removing local kpt configurations ..."
    if ${KPT} fn eval "${env_temp_subdir}/hydrated" --image="gcr.io/kpt-fn/remove-local-config-resources:v0.1" --truncate-output=false
    then
        status_kpt["${dir_id}"]=0
    else
        print_error "'kpt fn eval -i remove-local-config-resources' failed."
        error_counter=$(expr ${error_counter} + 1)
        status_kpt["${dir_id}"]=1
        return
    fi

    # re-add .gitkeep to handle empty folders (if all resources are removed)
    touch "${env_temp_subdir}/hydrated/.gitkeep"

    # check for rendered changes
    if git diff --no-index --quiet --exit-code "${env_deploy_dir}" "${env_temp_subdir}/hydrated"; then
        print_info "No changes detected for rendered resources."
        status_render_diff["${dir_id}"]=0
    else
        print_warning "Change detected, copying '${env_temp_subdir}/hydrated' to '${env_deploy_dir}' ..."
        warning_counter=$(expr ${warning_counter} + 1)
        diff_counter=$(expr ${diff_counter} + 1)
        status_render_diff["${dir_id}"]=2

        rm -rf "${env_deploy_dir}"
        cp -r "${env_temp_subdir}/hydrated" "${env_deploy_dir}"

        # print the git status, could be commented out if too verbose
        git status
    fi

    validate_yaml_in_dir "${env_deploy_dir}"

    echo "Function 'hydrate-env' completed for '${dir_id}'."
}

# function to run validation in a given directory, if environment variable is defined
validate_yaml_in_dir() {

    if [ -d "${1}" ]; then
        dir_to_validate="${1}"
    else
        print_warning "Invalid directory passed as argument in function 'validate_yaml_in_dir': '${1}'"
        warning_counter=$(expr ${warning_counter} + 1)
        return
    fi

    print_info "Starting validation in directory '${dir_to_validate}'"

    # defaults to always run, unless environment variable flags are set to false

    if [[ "${VALIDATE_YAML_KUBEVAL}" != "false" ]] ; then
        echo "Validating YAML files with 'kubeval' ..."
        # whether it's by design or not, kubeval can change quotes in annotations and remove duplicate resources (maybe 'kpt fn eval' does this?)
        # to workaround this, set an '--output' directory to avoid in-place modifications, the directory must not exist
        # to set strict=true, CRD schemas would need to be updated (with schema_location and additional_schema_locations)
        rm -rf "${TEMP_DIR}/kubeval/${dir_to_validate}"
        if ${KPT} fn eval -i kubeval:v0.3.0 "${dir_to_validate}" --output="${TEMP_DIR}/kubeval/${dir_to_validate}" --truncate-output=false \
            -- ignore_missing_schemas='true' strict='false'
        then
            print_success "'kubeval' was successful."
            status_validate_kubeval["${dir_id}"]=0
        else
            print_error "'kubeval' failed."
            error_counter=$(expr ${error_counter} + 1)
            status_validate_kubeval["${dir_id}"]=1
        fi
    else
        echo "Skipping YAML validation with 'kubeval'."
    fi

    if [[ "${VALIDATE_YAML_NOMOS}" != "false" ]] ; then
        echo "Validating YAML files with 'nomos vet' ..."
        # check if nomos CLI is installed
        if nomos help >/dev/null 2>&1 ; then
            echo "Running nomos with locally installed CLI."
            NOMOS="nomos"
        else
            NOMOS="docker run --volume "$PWD:/workspace" --workdir /workspace gcr.io/config-management-release/nomos:${NOMOS_VERSION}"
            echo "Running nomos with docker image: ${NOMOS}"
        fi
        if ${NOMOS} vet --no-api-server-check --source-format unstructured --path "${dir_to_validate}"
        then
            print_success "'nomos vet' was successful."
            status_validate_nomos["${dir_id}"]=0
        else
            print_error "'nomos vet' failed."
            error_counter=$(expr ${error_counter} + 1)
            status_validate_nomos["${dir_id}"]=1
        fi
    else
        echo "Skipping YAML validation with 'nomos'."
    fi
}

# helper function to print a status icon in a summary table
# 0=success, 1=error, 2=warning (only render diffs are considered warnings for summary)
print_status () {
    yellow='\033[1;33m'
    nocolor='\033[0m'
    case "${1}" in
        "0") printf "    \u2705    " # Green Check Mark Button
        ;;
        "1") printf "    \u274c    " # Red Cross Mark
        ;;
        "2") printf "   ${yellow}DIFF${nocolor}   "
        ;;
        *) printf "    --    "
        ;;
    esac
}

################################  MAIN  ################################

if ! grep "^${TEMP_DIR}/" .gitignore >/dev/null 2>&1 ; then
    print_error "TEMP_DIR/ is not in '.gitignore': ${TEMP_DIR}"
    exit 1
fi

# find every directory containing a source-base directory (i.e. the directory needs to be processed)
# iterate through each of these top level directories
for top_level_dir_to_process in $(find . -type d -name "${SOURCE_BASE_DIR}" -exec dirname {} \; | sort)
do
    echo "Found directory to process, moving into it: 'cd ${top_level_dir_to_process}' ..."
    cd "${top_level_dir_to_process}"

    # confirm that proper directory structure exists before continuing
    if [[ -d "${SOURCE_BASE_DIR}" && -d "${SOURCE_CUSTOMIZATION_DIR}" && -d "${DEPLOY_DIR}" ]]; then

        for env_subdir in experimentation dev preprod prod
        do
            # check if env. folder exists in source-customization
            if [ -d "${SOURCE_CUSTOMIZATION_DIR}/${env_subdir}" ]; then
                # create a unique text-based id for this hydration run
                dir_id="${top_level_dir_to_process}/${DEPLOY_DIR}/${env_subdir}"
                hydrate-env "${env_subdir}"
                dir_id=""
            else
                echo "'${SOURCE_CUSTOMIZATION_DIR}/${env_subdir}' does not exists, skipping."
            fi
        done
    else
        print_warning "Invalid SOURCE_BASE_DIR '${SOURCE_BASE_DIR}', SOURCE_CUSTOMIZATION_DIR '${SOURCE_CUSTOMIZATION_DIR}' or DEPLOY_DIR '${DEPLOY_DIR}'"
        warning_counter=$(expr ${warning_counter} + 1)
    fi
    # return to the root of the repo
    cd "${REPO_ROOT}"
done

# test if any directory was processed (i.e. array length is not 0) then print a summary table
if [[ ${#processed_dir_list[@]} -ne 0 ]]
then
    print_divider "Summary Table"
    echo "setters: The result of validating if all setters files in '${SOURCE_BASE_DIR}' exist in '${SOURCE_CUSTOMIZATION_DIR}/{env_subdir}'."
    echo "kpt: The result of executing kpt functions to render (hydrate) the YAML files."
    echo "no diff: The result of testing if hydrated files in '${DEPLOY_DIR}/{env_subdir} have changed.  These are counted as warnings and may fail the script in some conditions."
    echo "kubeval: The result of validating hydrated files in '${DEPLOY_DIR}/{env_subdir} with 'kpt fn eval -i kubeval'."
    echo "nomos vet: The result of validating hydrated files in '${DEPLOY_DIR}/{env_subdir} with 'nomos vet'."

    # printf can be used to format column width, however, it does not work with unicode emojis (used in print_status)
    printf '\n\n%-40s%-10s%-10s%-10s%-10s%-10s\n' 'processed directory' '  setters' '    kpt' ' no diff' ' kubeval' 'nomos vet'
    # loop through all processed directories and lookup its status in each dictionary array
    for processed_dir in ${processed_dir_list[@]}
    do
        printf "%-40s" "${processed_dir}"
        print_status "${status_validate_setters[${processed_dir}]}"
        print_status "${status_kpt[${processed_dir}]}"
        print_status "${status_render_diff[${processed_dir}]}"
        print_status "${status_validate_kubeval[${processed_dir}]}"
        print_status "${status_validate_nomos[${processed_dir}]}"
        printf "\n"
    done

    echo -e "\n\nProcessed directory count: ${#processed_dir_list[@]}"
    echo "Total errors count = ${error_counter}"
    echo "Total warnings count (can include some not shown in table) = ${warning_counter}"
    echo "Total diffs count (also counted as warnings) = ${diff_counter}"

    # check for errors and handle how to proceed
    if [ ${error_counter} -ne 0 ]; then
        print_error "The script encountered errors, please review and address them."
        exit_code=1
    else
        if [ ${diff_counter} -ne 0 ]; then
            print_warning "The script detected change in configurations."

            # push change if running from a pipeline on Pull Request
            # the BRANCH_NAME_TO_UPDATE and git configs must be set in yaml file
            # if [[ "${BUILD_REASON}" == "PullRequest" && "${BRANCH_NAME_TO_UPDATE}" != "" ]] ; then
            if [[ "${BRANCH_NAME_TO_UPDATE}" != "" ]] ; then
                print_info "The script is running in a PR pipeline and will attempt to commit and push changes to '${BRANCH_NAME_TO_UPDATE}' ..."
                if git checkout ${BRANCH_NAME_TO_UPDATE} \
                   && git add . \
                   && git commit -m "hydrate.sh detected diff in configurations" \
                   && git push origin "${BRANCH_NAME_TO_UPDATE}"
                then
                    print_success "The change was pushed to '${BRANCH_NAME_TO_UPDATE}'."
                else
                    print_error "The change was not pushed to '${BRANCH_NAME_TO_UPDATE}'."
                    exit_code=1
                fi
            else
                echo "The script will be set to fail because it's not running from a PR pipeline."
                echo "This may be normal if you've run it locally for the first time after making changes to '${SOURCE_BASE_DIR}' and/or '${SOURCE_CUSTOMIZATION_DIR}'"
                echo "If you see this message in a pre-commit hook: re-run git add, git commit and push the changes."
                exit_code=1
            fi
        else
            print_success "Hydration is complete and valid."
        fi
    fi
else
    print_warning "No directory processed.  If this is not intended, verify the repo's directory structure."
fi

echo -e "\nScript execution completed with exit_code = ${exit_code}\n"
exit $exit_code

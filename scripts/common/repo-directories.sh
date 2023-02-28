#!/usr/bin/env bash

# scripts are designed to run from the root of the deployment git repo
# the directories defined here are relative to that directory
DEPLOY_DIR="deploy"
SOURCE_BASE_DIR="source-base"
SOURCE_CUSTOMIZATION_DIR="source-customization"
TEMP_DIR="temp-workspace"

ENV_SUBDIRS="experimentation dev preprod prod"

# # check if source directories are valid
# if [ ! -d "${SOURCE_BASE_DIR}" ]; then
#     print_error "invalid SOURCE_BASE_DIR: ${SOURCE_BASE_DIR}"
#     exit 1
# fi
# if [ ! -d "${SOURCE_CUSTOMIZATION_DIR}" ]; then
#     print_error "invalid SOURCE_CUSTOMIZATION_DIR: ${SOURCE_CUSTOMIZATION_DIR}"
#     exit 1
# fi
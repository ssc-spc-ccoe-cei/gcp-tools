#!/bin/bash

# script to generate docs
#
# it reads the upstream section in the Kptfile of the current directory
# it first copies the current dir to LINUX_WORKDIR
# then, it executes generate-kpt-pkg-docs
# lastly, it copies back to the original directory the README.md
#
# TIP: You can add the following alias in your .bashrc
# alias generate-docs="bash $(git rev-parse --show-toplevel)/tools/scripts/kpt/generate-docs.sh"

LINUX_WORKDIR=/workdir
WINDOWS_WORKDIR=/c/workdir

# Remember source directory
srcDir=$(pwd)

# get the directory of this script
SCRIPT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# source print-colors.sh for better readability of the script's outputs
# shellcheck source-path=scripts/kpt # tell shellcheck where to look
source "${SCRIPT_ROOT}/../common/print-colors.sh"

# trap unhandled errors and unexpected termination
# shellcheck disable=SC2154 # disable 'var is referenced but not assigned'
trap 'status=$?; echo "Script terminating unexpectedly with exit code: ${status}"; exit ${status}' INT TERM ERR

# check if a Kptfile exists in the current directory
if [ -f Kptfile ]; then
  # check if the Kptfile has an upstream node
  if grep -q "upstream:" Kptfile; then
    # extract the repository/directory information from the upstream.git node
    repo=$(yq '.upstream.git.repo' Kptfile)
    print_info "upstream repo: $repo"
    directory=$(yq '.upstream.git.directory' Kptfile)
    print_info "upstream directory: $directory"

    #################
    # copy current directory on top of destination folder
    #################
    # delete content of destination folder
    if rm -Rf $LINUX_WORKDIR/*; then
      print_info "erasing $LINUX_WORKDIR folder"
    fi
    # copy all files and folders to the specified directory within the repository
    cp -r $srcDir/* $LINUX_WORKDIR
    cd $LINUX_WORKDIR

    chmod 777 README.md

    REPO_URL="${repo}.git${directory}/"
    print_info "running generate-kpt-pkg-docs"
    kpt fn eval -i generate-kpt-pkg-docs:unstable --mount type=bind,src="$WINDOWS_WORKDIR",dst="/tmp",rw=true -- readme-path=/tmp/README.md repo-path=$REPO_URL

    print_info "copying README.md back to original folder"
    cp -f README.md $srcDir
  else
    print_error "There is no upstream section in Kptfile"
  fi
else
  print_error "There is no Kptfile in current directory"
fi

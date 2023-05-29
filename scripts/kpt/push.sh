#!/bin/bash

# script to push a kpt package to upstream
#
# it reads the upstream section in the Kptfile of the current directory
# it first copies the current dir to a temp folder
# then, it cleans up the files to remove the extra kpt junk
# after that, it ask for a commit message
# lastly, it pushes the changes to the repo, branch, and folder that were define in the Kptfile/upstream
#
# TIP: You can add the following alias in your .bashrc
# alias kpt-push="bash $(git rev-parse --show-toplevel)/tools/scripts/kpt/push.sh"

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
    # extract the repository information from the upstream.git node
    repo=$(yq '.upstream.git.repo' Kptfile)
    print_info "upstream repo: $repo"
    directory=$(yq '.upstream.git.directory' Kptfile)
    print_info "upstream directory: $directory"
    ref=$(yq '.upstream.git.ref' Kptfile)
    print_info "upstream ref: $ref"

    # create a temporary directory to clone the repository into
    tmpdir=$(mktemp -d)
    cd "$tmpdir" || exit
    print_info "tmpdir: $tmpdir"

    #################
    # clone and checkout repo branch
    print_divider "clone and checkout repo branch"
    #################

    print_info "Cloning repo"
    git clone "$repo" repo
    cd repo || exit
    git fetch

    print_info "checking out branch $ref"
    if [ -z "$(git ls-remote --heads origin "$ref")" ]; then
      git checkout -b "$ref"
    else
      git checkout "$ref"
    fi


    dstDir="$tmpdir/repo$directory"

    #################
    # copy current directory on top of destination folder
    print_divider "copy current directory on top of destination folder"
    #################

    # delete content of destination folder
    if rm -r "$dstDir"; then
      print_info "erasing destination folder"
    fi
    # copy all files and folders to the specified directory within the repository
    cp -r "$srcDir" "$dstDir"
    cd "$dstDir" || exit

    #################
    # cleanup kpt junk
    print_divider "cleanup kpt junk"
    #################
    # remove the upstream and upstreamLock keys from the Kptfile
    print_info "Remove the upstream and upstreamLock keys from the Kptfile"
    yq eval 'del(.upstream)' -i Kptfile
    yq eval 'del(.upstreamLock)' -i Kptfile

    print_info "Loop through all .yaml files in current directory and subdirectories"
    # loop through all .yaml files in current directory and subdirectories
    find . -type f -name "*.yaml" | while read -r file; do
      # remove node "cnrm.cloud.google.com/blueprint"
      yq eval 'del(.metadata.annotations."cnrm.cloud.google.com/blueprint")' -i "$file"
      # remove node "internal.kpt.dev/upstream-identifier"
      yq eval 'del(.metadata.annotations."internal.kpt.dev/upstream-identifier")' -i "$file"
      # remove empty annotation node
      yq eval 'del(.metadata.annotations | select(length==0))' -i "$file"
      # remove strings  " # kpt-merge: .*"
      sed -i 's/ # kpt-merge: .*//' "$file"
    done

    ################
    # commit changes to upstream repo
    print_divider "commit changes to upstream repo"
    ################

    print_info "temp repo is here: $tmpdir/repo"

    git add .
    if [ -z "$(git status --porcelain)" ]; then
      print_warning "There are no uncommitted changes"
    else
      git status
      print_info "There are uncommitted changes"

      print_info "Enter a commit message (no double quotes required):"
      read -r commit_msg
      git commit -m "$commit_msg"
      # push changes to remote repository
      git push -u origin "$ref"
    fi
  else
    print_error "There is no upstream section in Kptfile"
  fi
else
  print_error "There is no Kptfile in current directory"
fi

# delete tmpdir
rm -Rf "$tmpdir"
# go back to original folder
cd "$srcDir" || exit
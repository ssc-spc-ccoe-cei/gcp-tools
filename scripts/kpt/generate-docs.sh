#!/bin/bash

# script to generate docs
#
# it reads the upstream section in the Kptfile of the current directory
# it first copies the current dir to LINUX_WORKDIR
# then, it executes generate-kpt-pkg-docs
# followed by, it copies back to the original directory the README.md
# then, it executes the inventory-controls.py
# then, it generates a markdown table and insert it between anchors in the securitycontrols.md
# then it copies the securitycontrols.md back to the original directory
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


################################
# README.md
###############################

# check if a Kptfile exists in the current directory
if [ -f Kptfile ]; then
  # check if the Kptfile has an upstream node
  if grep -q "upstream:" Kptfile; then
    # extract the repository/directory information from the upstream.git node
    repo=$(yq '.upstream.git.repo' Kptfile)
    print_info "upstream repo: $repo"
    directory=$(yq '.upstream.git.directory' Kptfile)
    print_info "upstream directory: $directory"

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

#######################
print_divider
#######################

##################
# securitycontrols.md
##################

# Execute inventory-controls.py
print_info "Execute inventory-controls.py"
python "${SCRIPT_ROOT}/../common/inventory-controls.py"

# Create a table in markdown format with the inventory
print_info "Create a table in markdown format with the inventory"
table="|Security Control|File Name|Resource Name|\n|---|---|---|\n"
# load the csv file using "%" as delimiter
while IFS='%' read -r securitycontrol filetype filename resourcename detail
do
  if [ "$filetype" == "kubernetes" ]; then
    table+="|${securitycontrol}|${filename}|${resourcename}|\n"
  fi
done < inventory.csv

# Open the file securitycontrols.md
exec 3<> securitycontrols.md

# Insert the table between the start and end anchors, overwriting any text already present between them
print_info "Insert the table between the start and end anchors, overwriting any text already present between them"
awk -v table="$table" '
    /<!-- BEGINNING OF SECURITY CONTROLS LIST -->/ { print; print table; f = 1 }
    /<!-- END OF SECURITY CONTROLS LIST -->/ { f = 0 }
    !f' securitycontrols.md >&3

# Close the file securitycontrols.md
exec 3>&-

# Copying securitycontrols.md back to original folder
print_info "Copying securitycontrols.md back to original folder"
cp -f securitycontrols.md $srcDir
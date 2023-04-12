#!/bin/bash

# Bash safeties: exit on error, pipelines can't hide errors
set -eo pipefail

# get the directory of this script and source print-colors.sh for better readability of the script's outputs
SCRIPT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_ROOT}/../common/print-colors.sh"

print_info "git status"
git status
print_info "------------"

print_info "source version"
echo $BUILD_SOURCEVERSION
print_info "------------"

# Load the config file
config_file="release-please-config.json"

packages=$(jq -r '.packages | keys[]' $config_file)

# Loop through each package and execute a command
for package in $packages; do
    print_info "-----------------------------------"
    print_info "treating package : $package"

    name=$(jq -r ".packages[\"$package\"].\"package-name\"" $config_file)
    print_info "name : $name"
    sep=$(jq -r ".packages[\"$package\"].\"tag-separator\"" $config_file)
    print_info "separator : $sep"

    # get the latest tag
    LAST_TAG=$(git tag -l "$name$sep*" --sort=-refname | head -n1)
    print_info "lastest tag: $LAST_TAG"

    # extract just the version
    package_version=$(echo $LAST_TAG | cut -d$sep -f2 | head -n 1)
    print_info "package_version : $package_version"

    # To list all commit messages that have affected a specific folder since a specific tag in chronological order
    LOGS=$(git log --pretty=format:"%s" --follow $LAST_TAG..$BUILD_SOURCEVERSION --reverse -- $package)
    VERSION=$package_version

    # while loop executes in a subshell because it is executed as part of the pipeline. Global variable cannot be updated from a subshell. You can avoid it by using lastpipe
    shopt -s lastpipe

    # loop through LOGS
    echo "$LOGS" | while read LOG; do
      print_info "parsing commit message: $LOG"
      PREFIX=$(echo $LOG | cut -d' ' -f1)
      case $PREFIX in
        "fix:")
            print_success "prefix 'fix' found"
            VERSION=$(echo $VERSION | awk -F. '{$3++; OFS="."; print $1,$2,$3}')
            ;;
        "feat:")
            print_success "prefix 'feat' found"
            VERSION=$(echo $VERSION | awk -F. '{$(NF-1)++;$NF=0;print $0}' OFS=.)
            ;;
        "feat!:")
            print_success "prefix 'feat!' found"
            VERSION=$(echo $VERSION | awk -F. '{$(NF-2)++;$(NF-1)=0;$NF=0;print $0}' OFS=.)
            ;;
        "fix!:")
            print_success "prefix 'fix!' found"
            VERSION=$(echo $VERSION | awk -F. '{$(NF-2)++;$(NF-1)=0;$NF=0;print $0}' OFS=.)
            ;;
        *)
        print_warning "no valid prefix found"
        # If no valid prefix is found, increase patch version by 1
        VERSION=$(echo $VERSION | awk -F. '{$3++; OFS="."; print $1,$2,$3}')
        ;;
      esac
      print_info "new version: $VERSION"
    done
    print_info "final version: $VERSION"
    # Create the tag
    # git tag $name$sep$VERSION
    print_success "Created tag: $name$sep$VERSION"
done

    # # Determine the new version based on commit messages
    # git log --pretty=format:"%s" --grep="^feat[!:](\|\!)" >/dev/null
    # if [ $? -eq 0 ]; then
    #     # Increment the minor version for feature changes
    #     new_version=$(semver --increment minor $package_version)
    #     new_entry="## $new_version\n\n### Features\n\n"
    #     git log --pretty=format:"%s" --grep="^feat[!:](\|\!)" | sed -e 's/^/* /' >> new_entry
    # else
    #     git log --pretty=format:"%s" --grep="^fix:" >/dev/null
    #     if [ $? -eq 0 ]; then
    #         # Increment the patch version for bug fixes
    #         new_version=$(semver --increment patch $package_version)
    #         new_entry="## $new_version\n\n### Bug Fixes\n\n"
    #         git log --pretty=format:"%s" --grep="^fix:" | sed -e 's/^/* /' >> new_entry
    #     else
    #         # No relevant commit messages, keep the same version
    #         new_version=$package_version
    #         new_entry=""
    #     fi
    # fi

    # # Prepend the new entry to the existing changelog file
    # changelog_file="CHANGELOG.md"
    # if [ -f "$changelog_file" ]; then
    #     tmp_file=$(mktemp)
    #     echo -e "$new_entry$(cat $changelog_file)" > $tmp_file
    #     mv $tmp_file $changelog_file
    # else
    #     echo -e "$new_entry" > $changelog_file
    # fi

    # echo "Updating version for package $package from $package_version to $new_version and adding changelog entry"
    # # Insert your command here to update the package version, using the $package and $new_version variables

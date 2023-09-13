#!/bin/bash

# script to create a tag that uses semantic versioning for each package(folder).
# the CONFIG_FILE contains the information for each package and it's tag format
#
# the commit messages are evaluated to determine what number (major or minor or patch) should be increased
# they need to use one of the following prefixes :
# fix: which represents bug fixes, and correlates to a SemVer patch.
# feat: which represents a new feature, and correlates to a SemVer minor.
# feat!:, or fix!: which represent a breaking change (indicated by the !) and will result in a SemVer major.
# doc: which represents an update to documentation won't modify the version but will move the tag to the new commit.
# commit message not following this convention correlates to a SemVer patch
# https://www.conventionalcommits.org/en/v1.0.0/


# bash safeties: exit on error, pipelines can't hide errors
set -eo pipefail

# get the directory of this script and source print-colors.sh for better readability of the script's outputs
SCRIPT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source-path=scripts/cicd # tell shellcheck where to look
source "${SCRIPT_ROOT}/../common/print-colors.sh"

print_info "This script assumes you are using Conventional Commit messages."
print_info "The prefixes you should be using are:"
print_info "fix: which represents bug fixes, and correlates to a SemVer patch."
print_info "feat: which represents a new feature, and correlates to a SemVer minor."
print_info "feat!:, or fix!: which represent a breaking change (indicated by the !) and will result in a SemVer major."
print_info "doc: which represents an update to documentation won't modify the version but will move the tag to the new commit."
print_info "commit message not following this convention correlates to a SemVer patch."
print_info "-----------------------------------"

# define CURRENT_BRANCH
# AzDO default
if [[ "${BUILD_SOURCEBRANCHNAME}" != "" ]] ; then
  export CURRENT_BRANCH="${BUILD_SOURCEBRANCHNAME}"
# GitHub default
elif [[ "${GITHUB_REF_NAME}" != "" ]] ; then
  export CURRENT_BRANCH="${GITHUB_REF_NAME}"
fi

# checkout CURRENT_BRANCH
git fetch --unshallow
git checkout "$CURRENT_BRANCH"
print_info "git status"
git status
print_info "-----------------------------------"

# load the config file
CONFIG_FILE="version-tagging-config.json"
# The keys_unsorted function will extract all the keys under packages.
# The select function with the startswith function and the negation operator (not) will exclude any key that starts with //comment.
packages=$(jq -r '.packages | keys_unsorted[] | select(startswith("//comment") | not)' $CONFIG_FILE)

# loop through each package and execute a command
print_info "Looping through packages"
for package in $packages; do
    print_info "-----------treating package : $package---------------"

    name=$(jq -r ".packages[\"$package\"].\"package-name\"" $CONFIG_FILE)
    print_info "package-name : $name"

    separator=$(jq -r ".packages[\"$package\"].\"tag-separator\"" $CONFIG_FILE)
    print_info "tag-separator : $separator"

    # get the latest tag
    # git tag is a command that displays a list of tags that exist in the Git repository.
    # -l "${name}${separator}*" specifies a pattern to match tags against. In this case, we're looking for tags that match the pattern ${name}${separator}*. The ${name} and ${separator} variables are interpolated into the pattern, so that we can search for tags that match the naming convention we're using for version tags. The * at the end of the pattern matches any string that follows the ${name}${separator} pattern.
    # --sort=-version:refname sorts the list of tags in reverse order by their version and reference name. This means that the most recent tag will be the first one in the list.
    # | head -n1 pipes the output of the git tag command to the head command, which limits the output to the first line of the input. This means that we're only interested in the most recent tag that matches the pattern ${name}${separator}*. If there are no matching tags, the command will output nothing.
    latest_tag=$(git tag -l "${name}${separator}*" --sort=-version:refname | head -n1)
    if [ -z "${latest_tag}" ]; then
      latest_tag="${name}${separator}0.0.0"
      print_warning "no tag found ! using : $latest_tag"

      # git log is a command that displays commit logs. With the flags and options provided, it will display a list of commit messages that match certain criteria.
      # --pretty=format:"%h %s" specifies the format of the log output. In this case, we're only interested in the commit hash and message, so we specify that the output should only include the hash (%h) and the subject line (%s) of each commit.
      # --follow tells git log to follow changes to the specified file ($package). This is useful if the file has been moved or renamed, as it will allow us to track its history across renames and moves.
      # --reverse tells git log to reverse the order of the output, so that the oldest commit is displayed first.
      # -- $package specifies the file or directory that we're interested in. This limits the output to only the commits that affected the specified file or directory ($package).
      logs=$(git log --pretty=format:"%h %s" --follow --reverse -- "$package")
    else
      print_info "latest tag: $latest_tag"

      # git log is a command that displays commit logs. With the flags and options provided, it will display a list of commit messages that match certain criteria.
      # --pretty=format:"%h %s" specifies the format of the log output. In this case, we're only interested in the commit hash and message, so we specify that the output should only include the hash (%h) and the subject line (%s) of each commit.
      # --follow tells git log to follow changes to the specified file ($package). This is useful if the file has been moved or renamed, as it will allow us to track its history across renames and moves.
      # $latest_tag.. specifies the range of commits that we're interested in. Specifically, we want to see all the commits that were made between the tag ($latest_tag) and now.
      # --reverse tells git log to reverse the order of the output, so that the oldest commit is displayed first.
      # -- $package specifies the file or directory that we're interested in. This limits the output to only the commits that affected the specified file or directory ($package).
      logs=$(git log --pretty=format:"%h %s" --follow "$latest_tag".. --reverse -- "$package")
    fi

    # validate that logs is not empty
    if [ -z "${logs}" ]; then
      print_warning "no new commit affecting package $package since tag $latest_tag"
    else
      # extract just the version
      version=$(echo "$latest_tag" | cut -d"${separator}" -f2 | head -n 1)
      print_info "version : $version"

      # while loop executes in a subshell because it is executed as part of the pipeline. Global variable cannot be updated from a subshell. You can avoid it by using lastpipe
      shopt -s lastpipe

      # loop through logs
      # to loop over each line of output from a command that can return a single line or multiple lines in Bash, you can use the while read loop. This loop reads input line by line until the end of the input.
      print_info "Looping through commits that have affected this package since $latest_tag"
      print_info "-----------"
      echo "$logs" | while read -r log; do
        orig_version=$version
        print_info "parsing commit: $log"
        hash=$(echo "$log" | cut -d' ' -f1)
        message=$(echo "$log" | cut -d' ' -f2-)
        # the patterns below accomodate for default commit message from azure devops PR which add the prefix Merged PR XXXX: in front of the PR title.
        case $message in
          *fix:*)
              print_success "prefix 'fix:' found"
              # The awk command uses -F. to specify the field separator as a period, which allows it to split the version number into its three components: major, minor, and patch.
              # The {$3++} command increments the value of the third component (i.e., the patch value) by one.
              # Finally, OFS="." sets the output field separator to a period, and print $1,$2,$3 prints the three components of the modified version number, separated by periods.
              # So, if the input version number is "1.2.3", the output of this command will be "1.2.4".
              version=$(echo "$version" | awk -F. '{$3++; OFS="."; print $1,$2,$3}')
              ;;
          *feat:*)
              print_success "prefix 'feat:' found"
              # {$(NF-1)++;$NF=0;print $0} is an awk script that increments the second-to-last field of the version number, sets the last field to zero. It then prints the modified version number. Here's a breakdown of each command:
              # $(NF-1)++ increments the second-to-last field of the version number.
              # $NF=0 sets the last field to zero.
              # print $0 prints the modified version number.
              version=$(echo "$version" | awk -F. '{$(NF-1)++;$NF=0;print $0}' OFS=.)
              ;;
          *feat!:*)
              print_success "prefix 'feat!:' found"
              # {$(NF-2)++;$(NF-1)=0;$NF=0;print $0} is an awk script that increments the third-to-last field of the version number, sets the second-to-last field to zero, and sets the last field to zero. It then prints the modified version number. Here's a breakdown of each command:
              # $(NF-2)++ increments the third-to-last field of the version number.
              # $(NF-1)=0 sets the second-to-last field to zero.
              # $NF=0 sets the last field to zero.
              # print $0 prints the modified version number.
              version=$(echo "$version" | awk -F. '{$(NF-2)++;$(NF-1)=0;$NF=0;print $0}' OFS=.)
              ;;
          *fix!:*)
              print_success "prefix 'fix!:' found"
              # The awk command uses the same format as feat!
              version=$(echo "$version" | awk -F. '{$(NF-2)++;$(NF-1)=0;$NF=0;print $0}' OFS=.)
              ;;
          *doc:*)
              print_success "prefix 'doc:' found"
              ;;
          *)
          # if no valid prefix is found, increase patch version by 1
          print_warning "no valid prefix found, increasing patch version by 1"
          # The awk command uses the same format as fix
          version=$(echo "$version" | awk -F. '{$3++; OFS="."; print $1,$2,$3}')
          ;;
        esac

        if [ "$version" != "$orig_version" ]; then
          print_info "new version: $version"

          # create the tag and push it to origin
          new_tag="${name}${separator}${version}"
          git tag "${new_tag}" "${hash}"
          git push origin tag "${new_tag}"
          print_success "Created tag ${new_tag} on commit ${hash}"
        else
          print_info "nothing to do"
        fi

        print_info "-----------"
      done
    fi
done

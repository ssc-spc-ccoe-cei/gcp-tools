#!/bin/bash

git status

git checkout $BUILD_SOURCEBRANCH

echo "----"
git status

# Load the input file
config_file="release-please-config.json"
release_file=".release-please-manifest.json"

packages=$(jq -r '.packages | keys[]' $config_file)

# Loop through each package and execute a command
for package in $packages; do
    echo "-----------------------------------"
    echo "treating package : $package"

    name=$(jq -r ".packages[\"$package\"].\"package-name\"" $config_file)
    echo "name : $name"
    sep=$(jq -r ".packages[\"$package\"].\"tag-separator\"" $config_file)
    echo "sep : $sep"

    # package=tier3
    package_version=$(jq -r ".$package" $release_file)
    echo "package_version : $package_version"

    LAST_TAG="$name$sep$package_version"
    echo "last_tag: $LAST_TAG"

    # To list all commit messages that have affected a specific folder since a specific tag,
    LOGS=$(git log --pretty=format:"%s" --follow $LAST_TAG..HEAD -- $package)
    VERSION=""
    echo "$LOGS" | while read LOG; do
      echo "parsing commit message: $LOG"
      PREFIX=$(echo $LOG | cut -d' ' -f1)
      case $PREFIX in
        "fix:")
            echo "fix"
            VERSION=$(echo $package_version | awk -F. '{$3++; OFS="."; print $1,$2,$3}')
            ;;
        "feat:")
            echo "feat"
            VERSION=$(echo $package_version | awk -F. '{$(NF-1)++;$NF=0;print $0}' OFS=.)
            ;;
        "feat!:")
            echo "feat!"
            VERSION=$(echo $package_version | awk -F. '{$(NF-2)++;$(NF-1)=0;$NF=0;print $0}' OFS=.)
            ;;
        "fix!:")
            echo "fix!"
            VERSION=$(echo $package_version | awk -F. '{$(NF-2)++;$(NF-1)=0;$NF=0;print $0}' OFS=.)
            ;;
        *)
        echo "no valid prefix found"
        # If no valid prefix is found, increase patch version by 1
        VERSION=$(echo $package_version | awk -F. '{$3++; OFS="."; print $1,$2,$3}')
        ;;
      esac
    done
    echo "new version: $VERSION"
    # Create the tag
    # git tag $name$sep$VERSION
    echo "Created tag: $name$sep$VERSION"
    # update manifest
    #jq -i ".$package = $VERSION" $release_file
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

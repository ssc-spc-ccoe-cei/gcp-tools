#!/bin/bash

# find folders that starts with "tier"
FOLDERS=$(find . -maxdepth 1 -type d -name "tier*" | sed 's|^\./||')

# iterate on folders
for FOLDER in $FOLDERS; do
  echo "-----------------------------------"
  echo "treating folder : $FOLDER"

  # get the /latest tag
  TAG=$(git tag -l "$FOLDER-*" --sort=-refname | head -n1)
  echo "latest tag: $TAG"

  # extract just the version
  VERSION=$(echo $TAG | cut -d- -f2 | head -n 1)
  echo "version: $VERSION"

  # determine if anything has changed since that tag for that folder
  if [ $(git diff --name-only $TAG HEAD | xargs -I {} dirname {} | grep -E "^$FOLDER") ]; then

    # To list all commit messages that have affected a specific file since a specific tag,
    LOGS=$(git log --pretty=format:"%s" --follow $TAG..HEAD -- $FOLDER)

    for LOG in $LOGS; do
      echo "parsing commit message: $LOG"
      PREFIX=$(echo $LOG | cut -d' ' -f1)
      case $PREFIX in
        "fix:")
            if [ -z "$VERSION" ]; then
                VERSION="0.0.1"
            else
                VERSION=$(echo $VERSION | awk -F. '{$3++; OFS="."; print $1,$2,$3}')
            fi
            ;;
        "feat:")
            if [ -z "$VERSION" ]; then
                VERSION="0.1.0"
            else
                VERSION=$(echo $VERSION | awk -F. '{$(NF-1)++;$NF=0;print $0}' OFS=.)
            fi
            ;;
        "feat!:")
            if [ -z "$VERSION" ]; then
                VERSION="1.0.0"
            else
                VERSION=$(echo $VERSION | awk -F. '{$(NF-2)++;$(NF-1)=0;$NF=0;print $0}' OFS=.)
            fi
            ;;
        "fix!:")
            if [ -z "$VERSION" ]; then
                VERSION="1.0.0"
            else
                VERSION=$(echo $VERSION | awk -F. '{$(NF-2)++;$(NF-1)=0;$NF=0;print $0}' OFS=.)
            fi
            ;;
        *)
        # If no valid prefix is found, increase patch version by 1
        if [ -z "$VERSION" ]; then
            VERSION="0.0.1"
        else
            VERSION=$(echo $VERSION | awk -F. '{$3++; OFS="."; print $1,$2,$3}')
        fi
        ;;
      esac
    done
    # Tag the folder with the semantic version
    # git tag $FOLDER-$VERSION
    echo "Created tag: $FOLDER-$VERSION"
  else
    echo "Nothing has change for that folder since tag : $TAG"
  fi
done
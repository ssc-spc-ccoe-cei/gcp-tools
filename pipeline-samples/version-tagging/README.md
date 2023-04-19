# Version Tagging

A sample for a way to manage git tags in a repository.

The tags generated combine a prefix and a version that follows [semantic versioning](https://semver.org/) (MAJOR.MINOR.PATCH).

1. Copy the sample `version-tagging.yaml` in the proper pipeline folder of your repo.
1. Copy the sample `version-tagging-config.json` in the root of your repo and update it according to your package/folder structure.
1. Add the pipeline.

## Requirements

- `tools` sub module.
- `version-tagging-config.json` in repo root.
- If using Azure DevOps:
  - "Create tag" permission on repo for user "{project} Build Service ({organization})". This may be enabled by default depending on security settings.
  - "Contribute" permission on repo for user "{project} Build Service ({organization})". This may only be required for the creation of the first tag depending on your environment.
- If using GitHub:
  - "contents" write permission on repo for GitHub Actions.  This may be enabled by default depending on security settings.

## Dependencies

- `tools/scripts/cicd/version-tagging.sh`

## Usage

When the PR is merged in the main branch, the pipeline will run automatically and create the tag for each package that have been modified.

The commit messages are evaluated to determine what number (major or minor or patch) should be increased
They need to use one of the following prefixes :
fix: which represents bug fixes, and correlates to a SemVer patch.
feat: which represents a new feature, and correlates to a SemVer minor.
feat!:, or fix!: which represent a breaking change (indicated by the !) and will result in a SemVer major.
doc: which represents an update to documentation won't modify the version but will move the tag to the new commit.
commit message not following this convention correlates to a SemVer patch
<https://www.conventionalcommits.org/en/v1.0.0/>

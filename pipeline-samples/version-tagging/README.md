# Version Tagging
A sample for a custom (basic) way to manage git tags and a changelog.

It follows [semantic versioning](https://semver.org/) (MAJOR.MINOR.PATCH).

> **It does NOT support a "v" prefix.**

1. Copy the sample `version-tagging.yaml` in the proper pipeline folder of your repo.
1. Copy the sample `VERSION.txt` and `CHANGELOG.md`* in the root of your repo.
1. Add the pipeline.

**If a changelog is not required, `VALIDATE_CHANGELOG` can be set to 'false' in `version-tagging.yaml`.*

## Requirements
- `tools` sub module.
- `VERSION.txt` in repo root.
- `CHANGELOG.md` in repo root, if a change log is required.
- If Azure DevOps:
  - "Create tag" permission on repo for user "{project} Build Service ({organization})". This may be enabled by default depending on security settings.
  - A "Build Validation Policy" (PR trigger).
- If GitHub:
  - "contents" write permission on repo for GitHub Actions.  This may be enabled by default depending on security settings.

## Dependencies
- `tools/scripts/cicd/version-tagging.sh`

## Usage

Before creating a PR, push these changes as well:
- Edit `VERSION.txt` to increment the version accordingly. (Reminder: no "v" prefix allowed.)
- Edit `CHANGELOG.md` to add an entry for the new version.  It must be enclosed in square brackets, for example [0.0.0].  Refer to the sample file for more info.

The PR trigger will run the pipeline to validate the new version tag.  No tag will be created.

When the PR is merged in the main branch, the pipeline will run again to re-validate and create the tag.

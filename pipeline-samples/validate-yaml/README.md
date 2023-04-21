# Validate YAML

A sample to validate that YAML configs have been properly hydrated.

If the `ENABLE_PUSH_ON_DIFF` environment variable is set to true, the pipeline will attempt to commit and push to the branch when a change to hydrated files is detected.

## Requirements

- `tools` sub module.
- A deployment repo based on gcp-repo-template.
- If using Azure DevOps:
  - A "Build Validation Policy" (PR trigger).
  - "Read" permission on repo for user "{project} Build Service ({organization})". This may be enabled by default depending on security settings.
  - "Contribute" permission on repo for user "{project} Build Service ({organization})" if `ENABLE_PUSH_ON_DIFF` is set to true.
- If using GitHub:
  - "contents" read permission on repo for GitHub Actions if `ENABLE_PUSH_ON_DIFF` is set to false.
  - "contents" write permission on repo for GitHub Actions if `ENABLE_PUSH_ON_DIFF` is set to true.

## Dependencies

- `tools/scripts/cicd/validate-yaml.sh`
- `tools/scripts/kpt/hydrate.sh`

## Usage

All validations will run by default, some can be disabled by adding environment variables in the "Validate YAML" step, for example:

```yaml
  env:
    VALIDATE_SETTERS_CUSTOMIZATION: 'false'
    VALIDATE_YAML_KUBEVAL: 'false'
    VALIDATE_YAML_NOMOS: 'false'
```

The PR trigger will run the pipeline to validate the hydration and YAML config files schemas.

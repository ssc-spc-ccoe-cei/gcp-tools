# Validate YAML
A sample to validate that YAML configs have been properly hydrated.

## Requirements
- `tools` sub module.
- A deployment repo based on gcp-repo-template.
- If using Azure DevOps:
  - A "Build Validation Policy" (PR trigger).
- If using GitHub:
  - "contents" read permission on repo for GitHub Actions.  This may be enabled by default depending on security settings.

## Dependencies
- `tools/scripts/cicd/validate-yaml.sh`

## Usage

All validations will run by default, some can be disabled by adding environment variables in the "Validate YAML" step, for example:
```yaml
  env:
    VALIDATE_SETTERS_CUSTOMIZATION: 'false'
    VALIDATE_YAML_KUBEVAL: 'false'
    VALIDATE_YAML_NOMOS: 'false'
```

The PR trigger will run the pipeline to validate the hydration and YAML config files schemas.


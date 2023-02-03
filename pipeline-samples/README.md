# Pipeline Samples

This folder contains samples of YAML definitions primarily for Azure DevOps Pipelines (`.azure-pipelines` directory). In some cases, the equivalent GitHub Actions (`.github` directory) may also be available.

## Adding / Editing a Pipeline

Simply copy a sample YAML file to your repo in the appropriate directory (`.azure-pipelines` or `.github/workflows`).

Each sample may have instructions specific to itself.

For general documentation on how to manage pipelines, please refer to the [gcp-documentation](https://github.com/ssc-spc-ccoe-cei/gcp-documentation/blob/main/Architecture/Pipelines.md) repo.

> **!!! Note when changing the `tools` sub module version !!!**<br>
Because the pipeline samples can have dependencies in the `scripts\` directory, it's important to compare with your copy if a change is required.
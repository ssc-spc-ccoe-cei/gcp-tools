#!/bin/bash

# script to bootstrap a Config Controller project
# AC-1: Implementation of access control

# Bash safeties: exit on error, pipelines can't hide errors
set -o errexit
set -o pipefail

# get the directory of this script
SCRIPT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# source print-colors.sh for better readability of the script's outputs
# shellcheck source-path=scripts/bootstrap # tell shellcheck where to look
source "${SCRIPT_ROOT}/../common/print-colors.sh"

if [ $# -eq 0 ]; then
    print_error "Usage: bash configure-kcc-access.sh PATH_TO_ENV_FILE"
    exit 1
fi

# source the env file
# shellcheck disable=SC1090 # don't look for sourced file, it won't exist in this repo
source "$1"

SA_EMAIL="$(kubectl get ConfigConnectorContext -n config-control \
    -o jsonpath='{.items[0].spec.googleServiceAccount}' 2> /dev/null)"

# AC-1
print_info "Create organization Admin IAM policy binding"
gcloud organizations add-iam-policy-binding "${ORG_ID}" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role=roles/resourcemanager.organizationAdmin \
  --condition=None

# AC-1
print_info "Create project IAM policy binding"
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member "serviceAccount:${SA_EMAIL}" \
  --role "roles/serviceusage.serviceUsageConsumer" \
  --project "${PROJECT_ID}"

print_info "Create git-creds for Repo access"
kubectl create secret generic git-creds --namespace="config-management-system" --from-literal=username="${GIT_USERNAME}" --from-literal=token="${TOKEN}"

cat << EOF > ./root-sync.yaml
apiVersion: configsync.gke.io/v1beta1
kind: RootSync
metadata:
  name: "${CONFIG_SYNC_NAME}"
  namespace: config-management-system
spec:
  sourceFormat: unstructured
  git:
    repo: "${CONFIG_SYNC_REPO}"
    branch: main # eg. : main
    dir: "${CONFIG_SYNC_DIR}" # eg.: csync/deploy/<env>
    revision: "${CONFIG_SYNC_VERSION}"
    auth: token
    secretRef:
      name: git-creds
EOF

print_info "Apply root sync"
kubectl apply -f root-sync.yaml

# Further steps
print_warning "The root-sync.yaml file should be checked into the <tier1-REPO>"
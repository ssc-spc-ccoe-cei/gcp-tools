# Bootstrap the Config Controller Project

The `setup-kcc.sh` automated script creates a project, the FW settings, a Cloud router, a Cloud NAT, a private service connect endpoint and a private Anthos Config Controller cluster.

The script requires a `.env` file to deploy the environment.

1. Your terminal should now be at the root of your `tier1` monorepo, on a new branch and with the tools submodule populated.

2. If it doesn't exist, create a `bootstrap/<env>` directory. It will be used to backup files generated during bootstrapping.

3. Copy the example.env file from the `tools/scripts/bootstrap` folder.

```bash
cp tools/scripts/bootstrap/.env.sample bootstrap/<ENV>/.env
```

4. **Important** Customize the new file with the appropriate values for the landing zone you are building.

5. Run the `setup-kcc` automated script:

```bash
bash tools/scripts/bootstrap/setup-kcc.sh [-af] <PATH TO .ENV FILE>
```
- `-a`: autopilot. It will deploy an autopilot cluster instead of a standard cluster.
- `-f`: folder_opt. It will bootstrap the landing zone in a folder instead than at the org level.

The config cluster is a private cluster and can only be accessed privately from within the VPC. This requires provisioning of a virtual machine to serve as a bastion host / proxy to access the private cluster.

## `git-creds` configuration

Once a bastion host / proxy vm is configured, to complete the configuration of the Anthos config controller cluster, `git-creds` secret must be configured in the cluster.  This secret contains credentials used to access the Git repository with the cloud resources code that the config controller will provision.

To create the secret:

```bash
# For Azure Devops, this is the name of the Organization
export GIT_USERNAME=<Git-Username>

# Export a TOKEN variable. Set its value to the PAT which has read access to the tier1 monorepo.
export TOKEN='xxxxxxxxxxxxxxx'

# Create git-creds secret
kubectl create secret generic git-creds --namespace="config-management-system" --from-literal=username="${GIT_USERNAME}" --from-literal=token="${TOKEN}"
```

## `root-sync` Configuration

Once the `git-creds` secret is created, the final step to configure the config controller cluster is to create a `RootSync` resource:

```bash
# Tier1 repo URL
export CONFIG_SYNC_REPO=<Repo for Config Sync> # tierX repo URL
export CONFIG_SYNC_VERSION='HEAD'
# Should default to csync/deploy/<env>
export CONFIG_SYNC_DIR=<Directory for config sync repo which syncs>

# Create the Root Sync yaml file
cat << EOF > ./root-sync.yaml
apiVersion: configsync.gke.io/v1beta1
kind: RootSync
metadata:
  name: root-sync
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

# Apply root sync
kubectl apply -f root-sync.yaml
```

The root-sync.yaml file should be checked into the tier1 repo
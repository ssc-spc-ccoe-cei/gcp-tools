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
bash tools/scripts/bootstrap/setup-kcc.sh [-afp] <PATH TO .ENV FILE>
```
- `-a`: autopilot. It will deploy an autopilot cluster instead of a standard cluster.
- `-f`: folder_opt. It will bootstrap the landing zone in a folder instead than at the org level.
- `-p`: public_endpoint_opt. It will deploy a cluster with a publicly accessible endpoint. Useful for development/testing purposes.

By default, the config cluster is a private cluster and can only be accessed privately from within the VPC. This requires provisioning of a virtual machine to serve as a bastion host / proxy to access the private cluster.

> Note that if your organization has an organization policy restricting VPC peering, it causes an issue when deploying the Anthos Config Controller cluster.  During cluster creation, a VPC peering is required with a Google owned project that contains the cluster control plane. To prevent this issue, a policy exemption for VPC peering should be created at the folder or project level.

## IAM and Access Configuration

Once a bastion host / proxy vm is configured, to complete the configuration, few additional tasks need to be performed:
- the Google IAM policy bindings need to be configured
- `git-creds` secret must be configured in the cluster. This secret contains credentials used to access the Git repository with the cloud resources code that the config controller will provision
- `root-sync` must be configured

The `configure-kcc-access.sh` script implements these required tasks. The script requires a `.env` file to configure the required variables.  This is the same `.env` file used by the `setup-kcc.sh` script. The script also requires a `TOKEN` variable that contains git access credentials.

> **NOTE**: The script requires connectivity to the cluster (in case of private cluster).

To run the script:

```bash
# Export a TOKEN variable. Set its value to the PAT which has read access to the tier1 monorepo.
export TOKEN='xxxxxxxxxxxxxxx'

bash tools/scripts/bootstrap/configure-kcc-access.sh <PATH TO .ENV FILE>
```

The script generates a `root-sync.yaml` file.  This file should be checked into the tier1 repo
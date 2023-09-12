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
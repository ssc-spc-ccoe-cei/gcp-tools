# GCP Development Environment

- [GCP Development Environment](#gcp-development-environment)
  - [Purpose](#purpose)
  - [Features](#features)
  - [Required Desktop Components](#required-desktop-components)
    - [Required Access](#required-access)
  - [Configuration](#configuration)
    - [VsCode](#vscode)
      - [Memory Limits](#memory-limits)
    - [Google Configuration On Windows](#google-configuration-on-windows)
      - [Initialize GCloud](#initialize-gcloud)
      - [Authenticate to Google Artifact Registry](#authenticate-to-google-artifact-registry)
    - [Container Installation](#container-installation)
  - [Maintenance Activities](#maintenance-activities)
    - [Updating Image](#updating-image)
    - [Build a new image](#build-a-new-image)
    - [Run a new image](#run-a-new-image)
    - [Push Image to Google Artifact Registry](#push-image-to-google-artifact-registry)

## Purpose

The gcptools/devcontainer repository includes version controlled software in a container, providing a homogenous software and runtime environment. The container facilitates GCP activities such as:

- Landing Zone creation & maintenance
- Operational activities
- Application workload deployment & maintenance

## Features

- Ubuntu 22.04 based image
- Light version management of container software through .env files
- Separated build and run process, leveraging docker compose
- Docker volume creation and mounting for a persistent storage layer
- Method of sharing files between the host OS and the container

## Required Desktop Components

- Windows 10, managed by your organization. 16GB ram or higher recommended
- WSL2 enabled, no virtual machine needed
- Docker Desktop, licensed
- VsCode
- Git for Windows
- Gcloud

### Required Access

- Access to a Google Cloud Artifact Registry or Container Registry to store, push and pull the built image

## Configuration

### VsCode

Use the Extensions pallet *(Ctrl+Shift+X)* to add in the following extensions (Minimal extensions required as this is only on Windows/PowerShell):
- Docker
- Remote Development

#### Memory Limits

To control WSL memory usage, you may add a file `%userprofile%/.wslconfig` with the following contents:

```plaintext
# Settings apply across all Linux distros running on WSL 2
[wsl2]
# Limits VM memory to use no more than 4 GB, this can be set as whole numbers using GB or MB
memory=4GB
# Sets the VM to use two virtual processors
processors=2
# Sets amount of swap storage space to 8GB, default is 25% of available RAM
swap=8GB
```

### Google Configuration On Windows

#### Initialize GCloud

Open VsCode, Open a PowerShell terminal. Initialize your Google SDK.

```PowerShell
PS C:\Users\LOCAL_USER\GCP\gcp-tools> gcloud init
Welcome! This command will take you through the configuration of gcloud.

Your current configuration has been set to: [default]

You can skip diagnostics next time by using the following flag:
  gcloud init --skip-diagnostics

Network diagnostic detects and fixes local network connection issues.
Checking network connection...done.
Reachability Check passed.
Network diagnostic passed (1/1 checks passed).

You must log in to continue. Would you like to log in (Y/n)?  Y
```

A browser will open and you will be presented with and authentication challenge. You may need to copy the URL provided by the gcloud init command if your last browser session was with another account/profile. Paste the link and authenticate with accounts.google.com

Google Cloud will want to confirm access for the SDK. Choose [Allow]

Back in the PowerShell Window, you will be prompted for a default project. Choose any project.

#### Authenticate to Google Artifact Registry

```PowerShell
gcloud auth configure-docker northamerica-northeast1-docker.pkg.dev

Adding credentials for: northamerica-northeast1-docker.pkg.dev
After update, the following will be written to your Docker config file located at [C:\Users\your-username\.docker\config.json]:
{
  "credHelpers": {
    "northamerica-northeast1-docker.pkg.dev": "gcloud"
  }
}

Do you want to continue (Y/n)? Y

Docker configuration file updated.

```

### Container Installation

Using Windows, launch VSCode. Open a PowerShell terminal.  

Create a directory ```c:\workdir```

Clone the repository `git clone https://github.com/ssc-spc-ccoe-cei/gcp-tools.git`

Git credential manager will open. Authenticate yourself. You may add your git token to $HOME/.git-credentials if you wish to auto login when using PowerShell

Open Terminal --> New Terminal.
```cd``` to the folder you choose to clone the repo into. Then ```cd .\devcontainer\run\```

Pull and start the container with the provided docker-compose.yaml & .env file values:

```shell
# from directory ...gcp-tools\devcontainer\run>
docker compose up -d
```
The ```docker compose up -d``` will pull a 3.0GB image and start a container of that image. If this is the first time starting the container a volume will be created and mounted to the $HOME directory.

Set your container to start on boot (optional, but recommended). Docker Desktop should start automatically.

```shell
docker update --restart unless-stopped cpedevcontainer
```
Now that your Container is up, you can use the Remote Explorer extension, right click on cpedevcontainer &#8594; Attach in new window.

## Maintenance Activities

From time to time the image will need to be updated, changed or added to. An example of how to do this is below.

### Updating Image

Using Windows, clone or pull the gcp-tools repo. Checkout a new branch.

```Powershell
git clone https://github.com/ssc-spc-ccoe-cei/gcp-tools.git
cd .\gcp-tools\
git checkout "mybranch"
cd .\devcontainer\build\
```

Modify ``...gcp-tools\devcontainer\Dockerfile & docker-compose.env`` as required.

Add or update the variables to the ```.env``` file(s).

Increment the TAG variable in ```build\.env``` using semantic versioning

### Build a new image

```Powershell
# from directory ...gcp-tools\devcontainer\build>
docker compose build
```

### Run a new image

Increment the TAG variable in ```run\.env```

```Powershell
# from directory ...gcp-tools\devcontainer\run>
docker compose up -d
```

Once satisfied with your changes, ensure the TAG variable in the  ```build\.env``` & the ```run\.env``` has your new TAG number.

### Push Image to Google Artifact Registry

```shell
docker push northamerica-northeast1-docker.pkg.dev/project-name/folder/container-name:VersionTag
```
Commit your change and push to github.com

Create a PR on the [GCP Tools Repo](https://github.com/ssc-spc-ccoe-cei/gcp-tools.git) "mybranch"

Once the PR is approved, merge to the main branch.

Users of the container can now pull the updated main branch to their workstations. This task can be done by:

```Powershell
cd .\gcp-tools\
git pull  # Allow a fast forward, there should be no conflicts
cd .\devcontainer\run\
docker compose up -d
docker update --restart unless-stopped cpedevcontainer
```

Enjoy!

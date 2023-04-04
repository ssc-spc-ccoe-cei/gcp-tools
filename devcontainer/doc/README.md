# GCP Development Environment

- [GCP Development Environment](#gcp-development-environment)
  - [Purpose](#purpose)
  - [Features](#features)
  - [Required Desktop Components](#required-desktop-components)
  - [Getting Started](#getting-started)
    - [Install WSL](#install-wsl2)
    - [Install Docker Desktop](#install-docker-desktop)
    - [GIT](#git)
    - [VsCode](#vscode)
    - [Gcloud Installation On Windows](#gcloud-installation-on-windows)
    - [Container Installation](#container-installation)
      - [Inside VsCode](#inside-vscode)
      - [Extras](#extras)
  - [Storage Volumes \& Windows Mapping](#storage-volumes--windows-mapping)
    - [Access Volume in Host OS](#access-volume-in-host-os)
  - [Maintenance Activities](#maintenance-activities)
    - [New Image Example](#new-image-example)

## Purpose

The gcptools/devcontainer repository includes version controlled software in a container, providing a homogenous software and runtime environment. The container facilitates GCP activities such as:

- Landing Zone creation & maintenance
- Operational activities
- Application workload deployment & maintenance

## Features

- Ubuntu 20.04 based image
- Version management of container software through .env files
- Separated build and run process, leveraging docker compose
- Docker volume creation and mounting for a persistent storage layer
- Method of sharing files between the host OS and the container

## Required Desktop Components

- Windows 10, managed by your organization. 16GB ram or higher recommended
- WSL2 enabled, no virtual machine needed
- Docker Desktop, licensed
- VsCode
- Git for Windows
- Admin Elevation

## Getting Started

*Note: These steps should be performed by your desktop administration group but are included here for completeness.*

### Install WSL2

Open PowerShell as Administrator (Start menu > PowerShell > right-click > Run as Administrator)

This shortcut step may be available to use depending on your version of Windows. If this step does not complete, the older method is listed as well below.

```shell
wsl --install
```

Older Method:

```shell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

Download the Linux Kernel extensions for WSL with the following link. [WSL Update](https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi)

Run the MSI file (wsl_update_x64.msi) and elevate to Admin via the UAC when prompted.

Restart your machine to complete the process.

After restarting, launch a powershell and set WSL2 to version 2

```PowerShell
wsl --set-default-version 2
```

Validate that WSL version 2 is running

```PowerShell
wsl -l -v
```

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

### Install Docker Desktop

Download the installer with the following link [Docker Desktop](https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe?utm_source=docker&utm_medium=webreferral&utm_campaign=dd-smartbutton&utm_location=module)

Locate the installer in your downloads folder, and launch it (Docker Desktop Installer.exe). Admin elevation is required via the Windows UAC mechanism.

Answer the dialogue questions as follows:

&#9745; Use WSL2 instead of Hyper-V (recommended)
&#9745; Add shortcut to desktop

Click  **[OK]**

Click **[Close and Logout]**

Open PowerShell as Administrator (Start menu > PowerShell > right-click > Run as Administrator)
Run the following command: ()

Hint:
To obtain your Windows username:
Press Control + Alt + Delete.
Click Task Manager.
Click Users. Your username will be listed under 'User'

```PowerShell
$myuser = Read-Host -Prompt 'Enter your Windows user name'
$mydomain =  [System.Environment]::GetEnvironmentVariables().USERDOMAIN_ROAMINGPROFILE
net localgroup docker-users $mydomain\$myuser /add
```

Reboot your PC.

Double click the Docker Desktop icon to start Docker Desktop.

Accept the "Docker Subscription Service Agreement".

When prompted, you may skip the tutorial, or start it to learn about Docker Desktop.

Open the Gear Icon for settings. Ensure the checkbox is enabled for:

&#9745; Start Docker Desktop when you log in

### GIT
<!-- Minimum requirements to pull from GCR, lz_admins  -->

Download Git for Windows [GIT for Windows](https://github.com/git-for-windows/git/releases/download/v2.39.0.windows.1/Git-2.39.0-64-bit.exe)

Double click the downloaded exe, (Git-2.39.0-64-bit.exe).

Accept the license by clicking **[Next]**

Leave the [destination] at defaults.

Select Components (leave as defaults). Click **[Next]**

Startup Menu Folder (leave as defaults). Click **[Next]**

Choose the default editor (Leave default VIM). You will be cautioned about this, but this is ok. Click **[Next]**

Adjusting the name of of the initial branch in new repositories (CHANGE to Override option, and leave as main).Click **[Next]**

Adjusting your PATH environment. Leave default (Git from the command line and also from 3rd party software). Click **[Next]**

Choosing the SSH executable (leave default Use bundled SSH). Click **[Next]**

Choosing HTTPS transport backend (Leave default, Use the OpenSSL library). Click **[Next]**

Configuring the line end conversions (CHANGE to Checkout as is, commit Unix-stile line endings). Click **[Next]**

Configuring the terminal Emulator to use with Git Bash (Leave default Use MinTTY). Click **[Next]**

Choose The default behavior of git pull (Leave default (fast forward or merge)). Click **[Next]**

Choose a credential helper (Leave default, Git Credential Manager). Click **[Next]**

Configuring extra options (Leave default, Enable file system caching). Click **[Next]**

Configuring experimental options (Leave default nothing selected). Click **[Install]**

Click **[Finish]**

### VsCode

Download [VsCode](https://code.visualstudio.com/download)

Choose "User installer".

Double Click the installer exe (VSCodeUserSetup-x64-1.74.1.exe).

&#9745; I accept the agreement, click **[Next]**

Accept the default path (C:\Users\your-username\AppData\Local\Programs\Microsoft VS Code).

Select start Menu Folder. Leave default (Visual Studio Code). Click **[Next]**

Click **[Install]**

Click **[Finish]**

Use the Extensions pallet *(Ctrl+Shift+X)* to add in the following extensions (Minimal extensions required as this is only on Windows/PowerShell):

- Docker
- Remote Development

### Gcloud Installation On Windows

Use the following link to download the [latest Google SDK](https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe)

Ensure you are DISCONNECTED from VPN prior to launching the installer in the next step.

Double click the downloaded installer (GoogleCloudSDKInstaller.exe)

Answer the prompts as follows:

Google Cloud CLI Setup

&#9744; Turn on screen reader mode
&#9744; Help Make Google Cloud CLI better by automatically sending anonymous use statistics to Google

Click **[Next]**

Accept the TOS by clicking **[Agree]**

(&#9679;) Single User. Click **[Next]**

Leave "Destination Folder" at default values. Click **[Next]**

Select components to to install
&#9745; Google Cloud CLI Core Libraries and tools
&#9745; Bundled Python
&#9745; Cloud Tools for Powershell
&#9745; Beta Commands (check this one as it is not by default)

Click **[Install]**

Click **[Next]**

Completing Google Cloud CLI Setup

Uncheck all the options

&#9744; Create Start Menu shortcut
&#9744; Create Desktop shortcut
&#9744; Start Google Cloud SDK Shell
&#9744; 'gcloud init' to configure the Google Cloud CLI

Click **[Finish]**

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

Back in the PowerShell Window, you will be prompted for a default project. Choose any project and hit return.

### Container Installation

#### Inside VsCode

Use either the VsCode source code extension (CTRL+Shift+G), or a PowerShell terminal. Clone the repository (`git clone https://github.com/ssc-spc-ccoe-cei/gcp-tools.git`) into a folder of your choosing.

Git credential manager will open. Authenticate yourself. You may add your git token to $HOME/.git-credentials if you wish to auto login when using PowerShell

Open Terminal --> New Terminal.
```cd``` to the folder you choose to clone the repo into. Then ```cd .\devcontainer\run\```

Authenticate to the Google Artifact Registry in the PowerShell Terminal.

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

Use the provided docker-compose.yaml to pull the image locally

```shell
# from ...gcp-tools\devcontainer\run>
docker compose up -d
```

The ```docker compose up -d``` will pull a 2.5GB image and start a container of that image. The container and image should be viewable inside of docker desktop.

Set your container to start on boot (optional, but recommended). Docker Desktop should start automatically.

```shell
docker update --restart unless-stopped cpedevcontainer
```

Now that your Container is up, you can use the docker extension to right click, (Attach Visual Studio Code)

Subsequent launches of Visual Studio Code should attach to your running container for your to use for your development environment.

#### Extras

Once inside your container, using a terminal configure git for yourself

```shell
git config --global user.name "username-ssc"
git config --global user.email "username@ssc-spc.gc.ca"
# Set git to use the credential memory cache
git config --global credential.helper cache
# Set the cache to timeout after 24 hour (setting is in seconds)
git config --global credential.helper 'cache --timeout=86400'
```

Add your favorite VsCode Extensions (suggestions)

- Code Spell Checker
- Docker
- Markdown All in One
- Trailing Spaces
- YAML (RedHat)

## Storage Volumes & Windows Mapping

A containers file systems should not be relied upon for durable storage purposes. Containers are to be treated as disposable artifacts. However, it is still a requirement (especially in a desktop environment) to have some persistent storage, regardless of the container's tag and lifecycle.

To ameliorate the temporal nature of the container, this solution uses a docker volume mount, connected to the container users $HOME directory. If there are any files in the container $HOME, such as .bashrc, they will be added to the docker volume when it is first created.

### Access Volume in Host OS

The container volume is accessible in the Windows Host OS though a network share provided by WSL. It can be accessed through:

```shell
\\wsl$\docker-desktop-data\data\docker\volumes\cpedevcontainer_vol\_data
```

** Please note that if you wish to edit files dropped into the Windows share, you must take ownership of them.

## Maintenance Activities

From time to time the image will need to be updated, changed or added to. An example of updating and distributing a new image is provided.

### New Image Example

Create a branch on [GCP Tools Repo](https://github.com/ssc-spc-ccoe-cei/gcp-tools.git)

Pull your the gcp-tools repo and checkout your branch

```shell
git pull https://github.com/ssc-spc-ccoe-cei/gcp-tools.git
git checkout "mybranch"
```

Update ```Dockerfile, docker-compose.env``` etc to add software or modify the environment as required.

Add or update the variables to the ```.env``` file(s).

Increment the TAG variable in ```build\.env```

Increment the TAG variable in ```run\.env```

Build a new image:

```shell
docker compose build
```

Test your changes locally

```shell
docker compose up
```

Once satisfied with your changes, ensure the TAG variable in the  ```build\.env``` & the ```run\.env``` has your new TAG number.

Push your code to Google Artifact Registry

```shell
docker push
```

Commit your change and push to github.com

Create a PR on the [GCP Tools Repo](https://github.com/ssc-spc-ccoe-cei/gcp-tools.git) "mybranch"

Once the PR is approved, commit & squash merge.

Users of the container can now pull the new branch to their workstations. This task can be done by:

```shell
git pull  # Allow a fast forward, there should be no conflicts
cd devcontainer\run
docker compose up
```

Enjoy!

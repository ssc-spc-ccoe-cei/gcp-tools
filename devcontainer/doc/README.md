# GCP Development Environment

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
- Git on for Windows

## Getting Started
---

<b>Note: These steps should be performed by your desktop administration group but are included here for completeness.</b>

### Install WSL

Open PowerShell as Administrator (Start menu > PowerShell > right-click > Run as Administrator)

This shortcut step may be available to use depending on your version of Windows. If this step does not complete, the older method is listed as well below.

```PowerShell
wsl --install
```

Older Method:
```PowerShell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

Download the Linux Kernel extensions for WSL. [Docker Desktop](https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi)


Run the MSI file (wsl_update_x64.msi) and elevate to Admin via the UAC when prompted.  

Restart your machine to complete the process.  

After restarting, launch a powershell and set WSL2 to version 2  

```PowerShell
wsl --set-default-version 2
```

### Install Docker Desktop

Download the installer [Docker Desktop](https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe?utm_source=docker&utm_medium=webreferral&utm_campaign=dd-smartbutton&utm_location=module)

Locate the installer in your downloads folder, and launch it (Docker Desktop Installer.exe). Admin elevation is required via the Windows UAC mechanism.  

Answer the dialogue questions as follows:  


&#9745; Use WSL2 instead of Hyper-V (recommended)  
&#9745; Add shortcut to desktop  

Click  [OK]

Click [Close and Logout]


Open PowerShell as Administrator (Start menu > PowerShell > right-click > Run as Administrator)  
Run the following command (substitute your organizations_domain\LOCAL_USER name):  

```PowerShell
net localgroup docker-users pwgsc-tpsgc-em\LOCAL_USER /add 
```

Reboot your PC  

Double click the Docker Desktop icon to start Docker Desktop.

Accept the "Docker Subscription Service Agreement"  

When prompted, you may skip the tutorial, or start it to learn about Docker Desktop.  


### GIT
<!-- TODO: Determine minimum requirements to pull from GCR. (Seems to be lz_admins)   -->

Download Git for Windows [GIT for Windows](https://github.com/git-for-windows/git/releases/download/v2.39.0.windows.1/Git-2.39.0-64-bit.exe)

Double click the downloaded exe, (Git-2.39.0-64-bit.exe)

Accept the license by clicking [Next]

Leave the [destination] at defaults  

Select Components (leave as defaults) and click [Next]  

Startup Menu Folder (leave as defaults) and click [Next]  

Choose the default editor (Leave default VIM) and click [Next]  

Adjusting the name of of the initial branch in new repositories (Change to Override option, and leave as main). Click n[Next]  

Adjusting your PATH environment. Leave default (Git from the command line and also from 3rd party software). Click [Next]  

Choosing the SSH executable (leave default Use bundled SSH). Click [Next]  

Choosing HTTPS transport backend (Leave default, Use the OpenSSL library). Click [Next]  

Configuring the line end conversions (CHANGE to Checkout as is, commit Unix-stile line endings). Click [Next]  

Configuring the terminal Emulator to use with Git Bash (Leave default Use MinTTY). Click [Next]  

Choose The default behavior of git pull (Leave default(fast forward or merge)). Click [Next]  

Choose a credential helper (Leave default, Git Credential Manager). Click [Next]  

Configuring extra options (Leave default, Enable file system caching). Click [Next]  

Configuring experimental options (Leave default nothing selected). Click [Install]  

Click [Finish]  

### VsCode

Download VsCode [VsCode](https://code.visualstudio.com/download)

Choose "User installer"  

Double Click the installer exe (VSCodeUserSetup-x64-1.74.1.exe)  

&#9745; I accept the agreement, click [Next]  

Accept the default path (C:\Users\your-username\AppData\Local\Programs\Microsoft VS Code)  

Select start Menu Folder. Leave default (Visual Studio Code), Click [Next]

Click [Install]  

Click [Finish]

### Gcloud Installation On Windows 

Download the SDK [Latest Google SDK](https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe)

Double click the downloaded installer (GoogleCloudSDKInstaller.exe)

Answer the prompts as follows:  

Google Cloud CLI Setup

[] Turn on screen reader mode
[] Help Make Google Cloud CLI better by automatically sending anonymous use statistics to Google

Click [Next]

Accept the TOS by clicking [Agree]

(&#9679;) Single User, click [Next]

Leave "Destination Folder" at default values, click [Next]

Select components to to install  
&#9745; Google Cloud CLI Core Libraries and tools  
&#9745; Bundled Python  
&#9745; Cloud Tools for Powershell  
&#9745; Beta Commands (check this one as it is not by default)  

Click [Install]  

Click [Next]  

Completing Google Cloud CLI Setup

Uncheck all the options

[] Create Start Menu shortcut  
[] Create Desktop shortcut  
[] Start Google Cloud SDK Shell  
[] Run 'gcloud init' to configure the Google Cloud CLI  

Click [Finish]


Open VsCode, Open a powershell terminal

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
A browser will open. You may need to copy the URL provided by the gcloud init command if your last browser session was with another account/profile. Paste the link and authenticate with accounts.google.com

Google Cloud will want to confirm access for the SDK. Choose [Allow]

Back in the PowerShell Window, you will be prompted for a default project. Choose any project and hit return.  

### Container Installation

clone repository button (https://dev.azure.com/gc-cpa/iac-gcp/_git/gcp-tools)

Choose a folder (make a new folder GCP or something similar)

Git credential manager will open. Choose/Use your Azure credentials (ds-sa) and follow the MFA process

You will be prompted to "Open the cloned repository", go ahead and Open.  

Trust the authors of this folder.

Open terminal --> new terminal.
cd  devcontainer/run



## Storage Volumes & Windows Mapping

A containers file systems should not be relied upon for durable storage purposes. Containers are to be treated as disposable artifacts. However, it is still a requirement (especially in a desktop environment) to have some persistent storage, regardless of the container's tag and lifecycle. 

To ameliorate the temporal nature of the container, this solution uses a docker volume mount. 

## Supplemental Guidance 

A) Container Run  
B) Login to GCR to pull container  
C) Command to ensure container comes up with OS (docker update --restart unless-stopped cpedevcontainer)
D) Add remote developer tools ### Put this into the vscode instructions






Maintenance


TODO:
I figure out using a volume mount (vs bind) does not overwrite the mounted directory (unless you tell it to), and leaves .bashrc intact as per the Dockerfile. It then is accessible via \\wsl$\docker-desktop-data\data\docker\volumes\cpedevcontainer_vol\_data. ​docker compose up​ creates the volume and it is persistent.  Permissions on files dropped from windows look like this: 

-rw-r--r-- 1 root    root       0 Dec 13 21:28 mikestest.txt 
drwxr-xr-x 2 root    root    4096 Dec 13 21:29 testfolder 

No more x bit set on files. 



### WIP
- Clone the repo, using VsCode (https://github.com/ssc-spc-ccoe-cei/gcp-tools)
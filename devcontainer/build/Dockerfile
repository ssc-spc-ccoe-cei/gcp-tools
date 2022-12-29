# Parent source image location is dockerhub.io
FROM ubuntu:20.04 

# Update values in .env for building a new version
# ARG is only accessable during the build process
ARG DEBIAN_FRONTEND=noninteractive
ARG CPE_USERNAME
ARG APT_TRANSPORT_HTTPS
ARG GNUPG
ARG CURL
ARG LSB_RELEASE
ARG UNZIP
ARG JQ
ARG WGET
ARG GIT
ARG TREE
ARG MAKE
ARG SOFTWARE_PROPERTIES_COMMON
ARG NET_TOOLS
ARG DOCKER_CE
ARG DOCKER_CE_CLI
ARG CONTAINERD_IO
ARG DOCKER_COMPOSE_PLUGIN
ARG BASH_COMPLETION
ARG GCLD_SDK

RUN  adduser --quiet  \
     --shell /bin/bash --home /home/${CPE_USERNAME} \
     --gecos "User" ${CPE_USERNAME}  \
     --disabled-password

RUN  apt-get update && \
     apt-get install -y apt-transport-https=${APT_TRANSPORT_HTTPS} && \
     apt-get install -y gnupg=${GNUPG} \
     curl=${CURL} \
     lsb-release=${LSB_RELEASE} \
     unzip=${UNZIP} \
     jq=${JQ} \
     wget=${WGET} \
     git=${GIT} \
     tree=${TREE} \
     make=${MAKE} \
     software-properties-common=${SOFTWARE_PROPERTIES_COMMON} \
     net-tools=${NET_TOOLS} \
     vim \
     sudo  \
     pkg-config \
     python3.8  \
     python-is-python3 && \
     curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg && \
     add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
     apt-get install -y docker-ce=${DOCKER_CE}  \
     docker-ce-cli=${DOCKER_CE_CLI} \
     containerd.io=${CONTAINERD_IO} \
     docker-compose-plugin=${DOCKER_COMPOSE_PLUGIN} \
     bash-completion=${BASH_COMPLETION}

RUN  wget -qO- https://storage.googleapis.com/cloud-sdk-release/google-cloud-cli-${GCLD_SDK}-linux-x86_64.tar.gz | tar zxv -C /usr/local/bin && \
     /usr/local/bin/google-cloud-sdk/install.sh --usage-reporting false --screen-reader true --command-completion true --additional-components kubectl gke-gcloud-auth-plugin beta alpha nomos gsutil app-engine-python-extras config-connector && \
     curl -LSso kpt_linux_amd64 https://github.com/GoogleContainerTools/kpt/releases/download/v1.0.0-beta.21/kpt_linux_amd64 && \
     chmod +x kpt_linux_amd64 && \
     mv kpt_linux_amd64 /usr/local/bin/google-cloud-sdk/bin/kpt && \
     git clone https://github.com/ahmetb/kubectx /opt/kubectx && \
     ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx && \
     ln -s /opt/kubectx/kubens /usr/local/bin/kubens && \
     usermod -a -G docker ${CPE_USERNAME}

RUN  echo ${CPE_USERNAME} ' ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/${CPE_USERNAME}

#TODO:
#https://www.openpolicyagent.org/docs/latest/cli/
#https://open-policy-agent.github.io/gatekeeper/website/docs/install
#https://github.com/open-policy-agent/gatekeeper/releases

USER ${CPE_USERNAME}

WORKDIR /home/${CPE_USERNAME}

ENV PATH "$PATH:/usr/local/bin/google-cloud-sdk/bin"

# Please note this has no effect on WSL as the volume mount is overtop of the container home, if on WSL/Ubuntu add to your .bashrc
RUN  echo "# START OF DOCKERFILE BASHRC MODS #"                              >> /home/${CPE_USERNAME}/.bashrc && \
     echo "source  /usr/local/bin/google-cloud-sdk/path.bash.inc"            >> /home/${CPE_USERNAME}/.bashrc && \
     echo "source /usr/local/bin/google-cloud-sdk/completion.bash.inc"       >> /home/${CPE_USERNAME}/.bashrc && \
     echo "source  /usr/local/bin/google-cloud-sdk/completion.bash.inc"      >> /home/${CPE_USERNAME}/.bashrc && \
     echo "COMPDIR=$(pkg-config --variable=completionsdir bash-completion)"  >> /home/${CPE_USERNAME}/.bashrc && \
     echo "sudo ln -sf ~/.kubectx/completion/kubens.bash \$COMPDIR/kubens"   >> /home/${CPE_USERNAME}/.bashrc && \
     echo "sudo ln -sf ~/.kubectx/completion/kubectx.bash \$COMPDIR/kubectx" >> /home/${CPE_USERNAME}/.bashrc && \
     echo "sudo chown root:docker /var/run/docker.sock"                      >> /home/${CPE_USERNAME}/.bashrc && \
     echo "sudo update-ca-certificates"                                      >> /home/${CPE_USERNAME}/.bashrc && \
     echo "# END OF DOCKERFILE BASHRC MODS #"                                >> /home/${CPE_USERNAME}/.bashrc

ENTRYPOINT ["tail", "-f", "/dev/null"]



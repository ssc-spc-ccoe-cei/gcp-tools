# Parent source image location is dockerhub.io
FROM ubuntu:22.04

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
ARG GATOR

# User
RUN  adduser --quiet --shell /bin/bash --home /home/${CPE_USERNAME} --gecos "User" ${CPE_USERNAME} --disabled-password


# RUN  apt-get update && \
#      apt-get install -y apt-transport-https=${APT_TRANSPORT_HTTPS} && \
#      apt-get install -y gnupg=${GNUPG} \
#      curl=${CURL} \
#      lsb-release=${LSB_RELEASE} \
#      unzip=${UNZIP} \
#      jq=${JQ} \
#      wget=${WGET} \
#      git=${GIT} \
#      tree=${TREE} \
#      make=${MAKE} \
#      software-properties-common=${SOFTWARE_PROPERTIES_COMMON} \
#      net-tools=${NET_TOOLS} \
#      vim \
#      sudo  \
#      pkg-config \
#      python3.8  \
#      python-is-python3 && \
#      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg && \
#      add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
#      apt-get install -y docker-ce=${DOCKER_CE}  \
#      docker-ce-cli=${DOCKER_CE_CLI} \
#      containerd.io=${CONTAINERD_IO} \
#      docker-compose-plugin=${DOCKER_COMPOSE_PLUGIN} \
#      bash-completion=${BASH_COMPLETION} && \
#      usermod -a -G docker ${CPE_USERNAME} && \
#      wget -qO- https://storage.googleapis.com/cloud-sdk-release/google-cloud-cli-${GCLD_SDK}-linux-x86_64.tar.gz | tar zxv -C /usr/local/bin && \
#      /usr/local/bin/google-cloud-sdk/install.sh --usage-reporting false --screen-reader true --command-completion true --additional-components kubectl gke-gcloud-auth-plugin beta alpha nomos gsutil app-engine-python-extras config-connector && \
#      curl -LSso kpt_linux_amd64 https://github.com/GoogleContainerTools/kpt/releases/download/v1.0.0-beta.21/kpt_linux_amd64 && \
#      chmod +x kpt_linux_amd64 && \
#      mv kpt_linux_amd64 /usr/local/bin/google-cloud-sdk/bin/kpt && \
#      git clone https://github.com/ahmetb/kubectx /opt/kubectx && \
#      ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx && \
#      ln -s /opt/kubectx/kubens /usr/local/bin/kubens && \
#      wget -qO- https://github.com/open-policy-agent/gatekeeper/releases/download/${GATOR}/gator-${GATOR}-linux-amd64.tar.gz | tar zxv -C /usr/local/bin

# BASE OS TOOLS
RUN  apt-get update && \
     apt-get install -y apt-transport-https && \
     apt-get install ca-certificates -y && \
     apt-get install -y gnupg \
     curl \
     lsb-release \
     unzip \
     jq \
     wget \
     git \
     tree \
     make \
     net-tools \
     vim \
     sudo \
     pkg-config \
     python3.10 \
     python-is-python3 \
     bash-completion \
     software-properties-common

# Docker

# RUN  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg && \
#      add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
#      apt-get install -y docker-ce=${DOCKER_CE}  \
#      docker-ce-cli=${DOCKER_CE_CLI} \
#      containerd.io=${CONTAINERD_IO} \
#      docker-compose-plugin=${DOCKER_COMPOSE_PLUGIN}

RUN  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg && \
     add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
     apt-get install -y docker-ce \
     docker-ce-cli \
     containerd.io \
     docker-compose-plugin && \
     usermod -a -G docker ${CPE_USERNAME}

# Google Cli
RUN  wget -qO- https://storage.googleapis.com/cloud-sdk-release/google-cloud-cli-${GCLD_SDK}-linux-x86_64.tar.gz | tar zxv -C /usr/local/bin && \
     /usr/local/bin/google-cloud-sdk/install.sh --usage-reporting false --screen-reader true --command-completion true --additional-components kubectl gke-gcloud-auth-plugin beta alpha nomos gsutil app-engine-python-extras config-connector

RUN  curl -LSso kpt_linux_amd64 https://github.com/GoogleContainerTools/kpt/releases/download/v1.0.0-beta.43/kpt_linux_amd64 && \
     chmod +x kpt_linux_amd64 && \
     mv kpt_linux_amd64 /usr/local/bin/google-cloud-sdk/bin/kpt

RUN  git clone https://github.com/ahmetb/kubectx /opt/kubectx && \
     ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx && \
     ln -s /opt/kubectx/kubens /usr/local/bin/kubens && \
     wget -qO- https://github.com/open-policy-agent/gatekeeper/releases/download/${GATOR}/gator-${GATOR}-linux-amd64.tar.gz | tar zxv -C /usr/local/bin

#TODO:
#https://www.openpolicyagent.org/docs/latest/cli/
#https://open-policy-agent.github.io/gatekeeper/website/docs/install
#https://github.com/open-policy-agent/gatekeeper/releases

RUN  echo ${CPE_USERNAME} ' ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/${CPE_USERNAME}

ENV PATH "$PATH:/usr/local/bin/google-cloud-sdk/bin"

# Please note this has no effect on WSL as the volume mount is overtop of the container home, if on WSL/Ubuntu add to your .bashrc
RUN  echo "# START OF ENVIRONMENT MODS #"                                    >> /etc/profile.d/my_environment_script.sh && \
     echo "source  /usr/local/bin/google-cloud-sdk/path.bash.inc"            >> /etc/profile.d/my_environment_script.sh && \
     echo "source /usr/local/bin/google-cloud-sdk/completion.bash.inc"       >> /etc/profile.d/my_environment_script.sh && \
     echo "source  /usr/local/bin/google-cloud-sdk/completion.bash.inc"      >> /etc/profile.d/my_environment_script.sh && \
     echo "COMPDIR=$(pkg-config --variable=completionsdir bash-completion)"  >> /etc/profile.d/my_environment_script.sh && \
     echo "sudo ln -sf ~/.kubectx/completion/kubens.bash \$COMPDIR/kubens"   >> /etc/profile.d/my_environment_script.sh && \
     echo "sudo ln -sf ~/.kubectx/completion/kubectx.bash \$COMPDIR/kubectx" >> /etc/profile.d/my_environment_script.sh && \
     echo "sudo chown root:docker /var/run/docker.sock"                      >> /etc/profile.d/my_environment_script.sh && \
     echo "sudo update-ca-certificates > /dev/null 2>&1"                     >> /etc/profile.d/my_environment_script.sh && \
     echo "# END OF ENVIRONMENT MODS #"                                      >> /etc/profile.d/my_environment_script.sh

USER ${CPE_USERNAME}

WORKDIR /home/${CPE_USERNAME}

ENTRYPOINT ["tail", "-f", "/dev/null"]
# Parent source image location is dockerhub.io
FROM ubuntu:22.04

# Update values in .env for building a new version
# ARG is only accessable during the build process
ARG DEBIAN_FRONTEND=noninteractive
ARG CPE_USERNAME
ARG GCLD_SDK
ARG GATOR
ARG KPT
ARG YQ
ARG AZ_CLI

# User
RUN  adduser --quiet --shell /bin/bash --home /home/${CPE_USERNAME} --gecos "User" ${CPE_USERNAME} --disabled-password

# Base OS Tools
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
     python3-pip \
     python3-yaml \
     bash-completion \
     software-properties-common

# Docker
RUN  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg && \
     add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
     apt-get install -y docker-ce \
     docker-ce-cli \
     containerd.io \
     docker-compose-plugin && \
     usermod -a -G docker ${CPE_USERNAME}

# Azure Cli
RUN  mkdir -p /etc/apt/keyrings && \
     curl -sLS https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/keyrings/microsoft.gpg > /dev/null && \
     chmod go+r /etc/apt/keyrings/microsoft.gpg && \
     AZ_DIST=$(lsb_release -cs) && \
     echo "deb [arch=`dpkg --print-architecture` signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $AZ_DIST main" | tee /etc/apt/sources.list.d/azure-cli.list && \
     apt-get update && \
     apt-get install azure-cli=${AZ_CLI}-1~$AZ_DIST && \
     az extension add --name azure-devops

# Google Cli
RUN  wget -qO- https://storage.googleapis.com/cloud-sdk-release/google-cloud-cli-${GCLD_SDK}-linux-x86_64.tar.gz | tar zxv -C /usr/local/bin && \
     /usr/local/bin/google-cloud-sdk/install.sh --usage-reporting false --screen-reader true --command-completion true --additional-components kubectl gke-gcloud-auth-plugin beta alpha nomos gsutil app-engine-python-extras config-connector

# kpt
RUN  wget https://github.com/GoogleContainerTools/kpt/releases/download/${KPT}/kpt_linux_amd64 -O /usr/local/bin/google-cloud-sdk/bin/kpt && \
     chmod +x /usr/local/bin/google-cloud-sdk/bin/kpt

# yq
RUN  wget https://github.com/mikefarah/yq/releases/download/${YQ}/yq_linux_amd64 -O /usr/bin/yq && \
    chmod +x /usr/bin/yq

# kubernetes and cluster helpers
RUN  git clone https://github.com/ahmetb/kubectx /opt/kubectx && \
     ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx && \
     ln -s /opt/kubectx/kubens /usr/local/bin/kubens && \
     wget -qO- https://github.com/open-policy-agent/gatekeeper/releases/download/${GATOR}/gator-${GATOR}-linux-amd64.tar.gz | tar zxv -C /usr/local/bin

RUN  echo ${CPE_USERNAME} ' ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/${CPE_USERNAME}

ENV PATH "$PATH:/usr/local/bin/google-cloud-sdk/bin"

# Modify .bashrc to source this file "/etc/profile.d/my_env_script.sh"
RUN  echo "# START OF ENVIRONMENT MODS #"                                                                  >> /etc/profile.d/my_env_script.sh && \
     echo "source  /usr/local/bin/google-cloud-sdk/path.bash.inc"                                          >> /etc/profile.d/my_env_script.sh && \
     echo "source /usr/local/bin/google-cloud-sdk/completion.bash.inc"                                     >> /etc/profile.d/my_env_script.sh && \
     echo "source  /usr/local/bin/google-cloud-sdk/completion.bash.inc"                                    >> /etc/profile.d/my_env_script.sh && \
     echo "COMPDIR=$(pkg-config --variable=completionsdir bash-completion)"                                >> /etc/profile.d/my_env_script.sh && \
     echo "sudo ln -sf ~/.kubectx/completion/kubens.bash \$COMPDIR/kubens"                                 >> /etc/profile.d/my_env_script.sh && \
     echo "sudo ln -sf ~/.kubectx/completion/kubectx.bash \$COMPDIR/kubectx"                               >> /etc/profile.d/my_env_script.sh && \
     echo "sudo chown root:docker /var/run/docker.sock"                                                    >> /etc/profile.d/my_env_script.sh && \
     echo "sudo chmod 774 /var/run/docker.sock"                                                            >> /etc/profile.d/my_env_script.sh && \
     echo "sudo update-ca-certificates > /dev/null 2>&1"                                                   >> /etc/profile.d/my_env_script.sh && \
     echo "alias kpt-hydrate='bash \`git rev-parse --show-toplevel\`/tools/scripts/kpt/hydrate.sh'"          >> /etc/profile.d/my_env_script.sh && \
     echo "alias kpt-push='bash \`git rev-parse --show-toplevel\`/tools/scripts/kpt/push.sh'"                >> /etc/profile.d/my_env_script.sh && \
     echo "alias generate-docs='bash \`git rev-parse --show-toplevel\`/tools/scripts/kpt/generate-docs.sh'"  >> /etc/profile.d/my_env_script.sh && \
     echo "# END OF ENVIRONMENT MODS #"                                                                    >> /etc/profile.d/my_env_script.sh && \
     echo "source /etc/profile.d/my_env_script.sh"                                                 >> /home/${CPE_USERNAME}/.bashrc

USER ${CPE_USERNAME}

WORKDIR /home/${CPE_USERNAME}

ENTRYPOINT ["tail", "-f", "/dev/null"]
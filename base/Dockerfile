FROM ubuntu:18.04

RUN echo "Updating base image" && \
    apt-get -y update && \
    apt-get -y upgrade

RUN echo "Installing Python 3" && \
    apt-get -y install python3-pip python3-dev && \
    cd /usr/local/bin && \
    ln -s /usr/bin/python3 python && \
    pip3 install --upgrade pip

RUN echo "Installing Open SSH" && \
    apt-get -y install openssh-client openssh-server && \
    rm -rf /etc/ssh/ssh_host_*  # remove auto-created host keys

RUN echo "Installing dev tools" && \
    apt-get -y install build-essential wget git curl jq nano \
    gzip unzip

RUN echo "Installing SDK" && \
    apt-get -y install apt-transport-https ca-certificates gnupg
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] \
    https://packages.cloud.google.com/apt cloud-sdk main" | \
    tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
RUN apt-get update && apt-get install google-cloud-cli

RUN echo "Cleanup after install" && \
    apt-get clean

COPY --from=golang:latest /usr/local/go/ /usr/local/go/
RUN echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile

# See: https://github.com/coder/code-server#getting-started
RUN echo "Installing VS Code server 4.9.1" && \
    (curl -fsSL https://code-server.dev/install.sh | sh -s -- --version=4.9.1)

# Merge in files from the assets directory
# See: https://source.corp.google.com/dev-con/workstation/base/Dockerfile
COPY ./base/assets/. /

# Ensure diff sha when only version is changed
COPY ./version /version

ENTRYPOINT ["/google/scripts/entrypoint.sh"]
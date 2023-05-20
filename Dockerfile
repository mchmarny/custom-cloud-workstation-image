# image versions
ARG BASE_IMAGE=ubuntu:22.04
ARG GO_IMAGE=golang:1.20.4

FROM $GO_IMAGE as go

FROM $BASE_IMAGE

# workstation variables
# https://github.com/coder/code-server/releases
# can't use 4.11 until proxy domain can be set
ARG CODE_VERSION=4.10.0

ENV CODE_VERSION=$CODE_VERSION

# Update base image
RUN apt-get -y update && apt-get -y upgrade

# Install python3
RUN apt-get -y install python3-pip python3-dev && \
    cd /usr/local/bin && \
    ln -s /usr/bin/python3 python && \
    pip3 install --upgrade pip

# Install openSSH
RUN apt-get -y install openssh-client openssh-server && \
    rm -rf /etc/ssh/ssh_host_*  # remove auto-created host keys

# Install dev tools
RUN apt-get -y install build-essential curl git gpa gzip jq \
    nano seahorse unzip wget

# Install sdk
RUN apt-get -y install apt-transport-https ca-certificates gnupg
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] \
    https://packages.cloud.google.com/apt cloud-sdk main" | \
    tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
RUN apt-get update && apt-get install google-cloud-cli

# Install go
COPY --from=go /usr/local/go/ /usr/local/go/
RUN echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile

# Install vs.code
# https://github.com/coder/code-server#getting-started
RUN curl -fsSL https://code-server.dev/install.sh | \
    sh -s -- --version=$CODE_VERSION
    
# Install golangci-lint
RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | \
    sh -s -- -b $(go env GOPATH)/bin 

# One more update the vs.code isntalled packages
RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get clean

# Merge in files from the assets directory
# https://source.corp.google.com/dev-con/workstation/base/Dockerfile
COPY ./assets/. /

# Ensure diff sha when only version is changed
COPY ./version /version

# Set the entrypoint
ENTRYPOINT ["/google/scripts/entrypoint.sh"]

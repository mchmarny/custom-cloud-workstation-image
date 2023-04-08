FROM ubuntu:18.04

RUN \
    echo "Updating base image" && \
    apt-get -y update && \
    apt-get -y upgrade

RUN \
    echo "Installing Python 3" && \
    apt-get -y install python3-pip python3-dev && \
    cd /usr/local/bin && \
    ln -s /usr/bin/python3 python && \
    pip3 install --upgrade pip

RUN \
    echo "Installing Open SSH" && \
    apt-get -y install openssh-client openssh-server && \
    rm -rf /etc/ssh/ssh_host_*  # remove auto-created host keys

RUN \
    echo "Installing git" && \
    apt-get -y install git

RUN \
    echo "Installing curl" && \
    apt-get -y install curl

RUN \
    echo "Installing repo" && \
    curl -o /usr/bin/repo https://storage.googleapis.com/git-repo-downloads/repo && \
    chmod a+rx /usr/bin/repo

RUN \
    echo "Installing VS Code server 4.9.1" && \
    (curl -fsSL https://code-server.dev/install.sh | sh -s -- --version=4.9.1)

# Install Go
COPY --from=golang:latest /usr/local/go/ /usr/local/go/
RUN echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile

COPY ./scripts/. /

# Ensure diff sha when only version is changed
COPY .version /.version

ENTRYPOINT ["/entrypoint"]

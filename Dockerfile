FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest

# ennvironment variables and labels
ARG VERSION=v0.0.1-default
ENV VERSION=${VERSION}
LABEL workstation.version="${VERSION}"

# go
COPY --from=golang:1.20.1 /usr/local/go/ /usr/local/go/

# start
WORKDIR /google/scripts
ENTRYPOINT ["./entrypoint.sh"]

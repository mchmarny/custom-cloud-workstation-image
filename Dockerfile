ARG BASE_IMG=us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest
ARG RUN_IMG=golang:1.20@sha256:6e835db45c7d88e12b057c0638814c2b266f69143437e4110b8bec5cfc7fa53b

# BASE
FROM $BASE_IMG as base

WORKDIR /src/
COPY . /src/

# runtime args
ARG VERSION=v0.0.1-default

# args to env vars
ENV VERSION=${VERSION}

# RUN
FROM $RUN_IMG
LABEL workstation.version="${VERSION}"
COPY --from=base /etc/workstation-startup.d/ /etc/workstation-startup.d/
COPY --from=base /google/scripts/entrypoint.sh /google/scripts/entrypoint.sh

WORKDIR /google/scripts
ENTRYPOINT ["./entrypoint.sh"]

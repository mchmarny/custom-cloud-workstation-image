ARG BASE_IMG=us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest
ARG RUN_IMG=golang@sha256:745aa72cefb6f9527c1588590982c0bdf85a1be5d611dda849e54b5dbf551506

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
COPY --from=base /opt/code-oss/ /opt/code-oss/
COPY --from=base /google/scripts/ /google/scripts/
COPY --from=base /usr/bin/workstation-startup /usr/bin/workstation-startup

WORKDIR /google/scripts
ENTRYPOINT ["./entrypoint.sh"]

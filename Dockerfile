ARG BASE_IMG=us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest
ARG RUN_IMG=cgr.dev/chainguard/go:latest

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
COPY --from=base /usr/bin/workstation-startup/ /usr/bin/workstation-startup/
COPY --from=base /etc/workstation-startup.d/ /etc/workstation-startup.d/
COPY --from=base /google/scripts/entrypoint.sh /google/scripts/entrypoint.sh
COPY --from=base /opt/code-oss/ /opt/code-oss/


WORKDIR /google/scripts
ENTRYPOINT ["./entrypoint.sh"]

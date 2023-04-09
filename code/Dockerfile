FROM us-west1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest

RUN echo "Removing unecessary components" && \
    apt -y remove \
    php8.2 php-common php8.2-cli php8.2-common php8.2-opcache php8.2-readline \
    openjdk-11-jdk-headless openjdk-11-jdk openjdk-11-jre-headless openjdk-11-jre java-common \
    google-cloud-sdk-bigtable-emulator google-cloud-sdk-cbt google-cloud-sdk-datastore-emulator google-cloud-sdk-local-extract \
    temurin-11-jdk temurin-17-jdk 

RUN echo "Updating what's left on base image" && \
    apt-get update && apt-get -y upgrade && apt-get -y clean

COPY --from=golang:latest /usr/local/go/ /usr/local/go/
RUN echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile

# Ensure diff sha when only version is changed
COPY ./version /version

ENTRYPOINT ["/google/scripts/entrypoint.sh"]
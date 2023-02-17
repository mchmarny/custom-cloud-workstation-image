FROM us-west1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest

# remove unecessary packages
RUN apt -y remove php8.2 php-common php8.2-cli php8.2-common php8.2-opcache php8.2-readline openjdk-11-jdk-headless openjdk-11-jdk openjdk-11-jre-headless openjdk-11-jre java-common google-cloud-sdk-bigtable-emulator google-cloud-sdk-cbt google-cloud-sdk-datastore-emulator google-cloud-sdk-kpt google-cloud-sdk-minikube google-cloud-sdk-skaffold

# update what's left
RUN apt-get update && apt-get -y upgrade

# add go
COPY --from=golang:1.20.1 /usr/local/go/ /usr/local/go/

# start
WORKDIR /google/scripts
ENTRYPOINT ["./entrypoint.sh"]

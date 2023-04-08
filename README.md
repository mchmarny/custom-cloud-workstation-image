# custom-cloud-workstation-image

```shell
docker build \
    -t us-west1-docker.pkg.dev/cloudy-build/custom-cloud-workstation-image/ws-dev \
    .
```

```shell
docker container run --rm -it \
    --entrypoint /bin/sh \
    us-west1-docker.pkg.dev/cloudy-build/custom-cloud-workstation-image/ws-dev
```
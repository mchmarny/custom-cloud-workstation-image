# custom-cloud-workstation-image

Custom Cloud Workstations image

## setup

> Given this is a custom image build example, the assumption is you already know the basic. For brevity, these setup instructions will skip the details for common steps. Terraform setup is coming soon for more automated deployment process.

Start by [forking this repo](https://github.com/mchmarny/custom-cloud-workstation-image/fork) and closing it locally. When done, export the following environment variables with your own values: 

```shell
# GCP project ID
export PROJECT_ID="your-gcp-project-id"
# GCP region where you want to run the scans
export REGION="us-west1"
# GitHub user is the org/username where you forked this repo 
export GH_USER="your-github-username"
# Artifact Registry name where you want to publish the image
# For example: us-docker.pkg.dev/$PROJECT_ID/ws-images
export AR_REPO="ws-images"
```

# build

Next, create a GitHub trigger in GCB using the [provided build configurations file](cloudbuild.yaml). More detail about the parameters used below [here](https://cloud.google.com/build/docs/automating-builds/create-manage-triggers#build_trigger):

> Note, if you get `Repository mapping does not exist` error, follow the provided URL to connect that repo to your project.

```shell
gcloud beta builds triggers create github \
    --name=custom-cloud-workstation-image \
    --project=$PROJECT_ID \
    --region=$REGION \
    --repo-name=custom-cloud-workstation-image \
    --repo-owner=$GH_USER \
    --tag-pattern="v*" \
    --build-config=cloudbuild.yaml \
    --substitutions=_REPO=$AR_REPO,_IMAGE=go-code
```

To trigger an actual build of this image, first, update the [version](./version) file to the next canonical version (e.g. `v0.1.10`), commit and push that change in git, and run `make tag`.

# disclaimer

This is my personal project and it does not represent my employer. While I do my best to ensure that everything works, I take no responsibility for issues caused by this code.
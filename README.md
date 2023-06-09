# custom-cloud-workstation-image

Cloud Workstations provides number of [pre-configured base images](https://cloud.google.com/workstations/docs/customize-container-images) that include most of the common tools. You can extend these base images, or you can crete a custom image that has the minimal configuration for your specific use-case, and nothing else. 

This custom Cloud Workstations pipeline image creates an image optimized for [Go](https://go.dev/) development in [VS Code](https://github.com/microsoft/vscode), with automatic Cloud Workstations configuration update. You can add your own tools in [Dockerfile](./Dockerfile), or provide additional user-specific options for new users in [setup](assets/setup) for things like VS Code default settings and git configuration. 

This pipeline includes new image build and workstation configuration update with that image: 

* On new git (version) tag, see [updates](#updates)
* On daily schedule, see [schedule](#schedule) 

> More information about using custom images with Cloud Workstations available [here](https://cloud.google.com/workstations/docs/customize-container-images).

## on time setup

Start by [forking this repo](https://github.com/mchmarny/custom-cloud-workstation-image/fork) and cloning it locally. Next, navigate into the new directory, and export the following environment variables with your own values: 

> For brevity, these setup will skip the details for common steps, the assumption is you already are familiar with Cloud Build builds and Cloud Workstation configuration. A Terraform setup is coming soon for more automated deployment process.

```shell
# GCP project ID
export PROJECT_ID="your-gcp-project-id"
# GCP region where you want to run the scans
export REGION="us-west1"
# GitHub user is the org or username where you forked this repo 
export GH_USER="your-github-username"
# Artifact Registry name where you want to publish the image
# For example: us-west1-docker.pkg.dev/$PROJECT_ID/ws-images
export AR_REPO="ws-images"
# Cloud Workstations prefix
# helpful when you want to create multiple workstations
export WS_NAME="dev"
# Project Number 
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
```

Next, create a service account which will be used to run the workstation: 

```shell
gcloud iam service-accounts create $WS_NAME-workstation-runner
```

Export accounts: 

```shell
export RUNNER_SA="$WS_NAME-workstation-runner@$PROJECT_ID.iam.gserviceaccount.com"
export BUILDER_SA="$PROJECT_NUMBER@cloudbuild.gserviceaccount.com"
```

At minimum, that service account has to have these roles: 

> Complete list of rights included in each one these roles is available [here](https://cloud.google.com/iam/docs/understanding-roles) 

```shell
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$RUNNER_SA" \
    --role="roles/workstations.workstationCreator" \
    --condition=None
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$RUNNER_SA" \
    --role="roles/workstations.operationViewer" \
    --condition=None
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$RUNNER_SA" \
    --role="roles/artifactregistry.reader" \
    --condition=None
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$BUILDER_SA" \
    --role="roles/workstations.admin" \
    --condition=None
```

> Depending on what you will do with this workstation, you may want to add additional roles. 

### registry    

Create Artifact Registry repository: 

```shell
gcloud artifacts repositories create $AR_REPO \
    --location=$REGION \
    --repository-format=docker
```

### trigger

To build a custom image for Cloud Workstations (CW) using the provided docker file, first, create a GitHub trigger in GCB using the [provided build configurations file](cloudbuild.yaml). More detail about the parameters used below [here](https://cloud.google.com/build/docs/automating-builds/create-manage-triggers#build_trigger):

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
    --substitutions=_REPO=$AR_REPO,_CLUSTER=$WS_NAME-cluster,_CONFIG=$WS_NAME-config
```

### image

To trigger an actual build of this image, first, update the [version](./version) file to the next canonical version, commit and push that change in git, and run:

```shell
git tag -s -m "version bump" $(cat ./version)
git push origin $(cat ./version)
```

> Alternatively, you can run `make tag` to automate the above steps. 

### cluster 

This section will overview the Cloud Workstation configuration to use the above created image. Create a cluster: 

> More info on the parameters available in this command [here](https://cloud.google.com/sdk/gcloud/reference/beta/workstations/clusters/create)

```shell
gcloud beta workstations clusters create $WS_NAME-cluster \
    --project=$PROJECT_ID \
    --region=$REGION \
    --async
```

You only have to run this once, but this process can take as much as 20 min. Use the `describe` command to check on its status:

```shell
gcloud beta workstations clusters describe $WS_NAME-cluster \
    --project=$PROJECT_ID \
    --region=$REGION
```

The presence of `"reconciling": true` indicates that the cluster **is still being provisioned**. When complete, the response of the above command will look something like this (notice `network` is now populated): 

```json
{
  "createTime": "2023-04-08T22:34:52.290190289Z",
  "name": "projects/project/locations/us-west1/workstationClusters/ws-demo-cluster",
  "network": "projects/project/global/networks/default",
  "subnetwork": "projects/project/regions/us-west1/subnetworks/default",
  "updateTime": "2023-04-08T22:49:16.878931635Z"
}
```

### config

Once the cluster is configured and the above `describe` command returns confirmation with `network` information, you are ready to create workstation configuration. To do this you will need some information. 

Next, get the fully-qualified URI (with digest) of the image created by the above step:

> That assumes you have tagged your repo already, and the Cloud Build pipeline successfully built the image.

```shell
export IMAGE=$(gcloud artifacts docker images list \
    $REGION-docker.pkg.dev/$PROJECT_ID/$AR_REPO/ws-go-code \
    --format='value[separator="@"](IMAGE,DIGEST)' \
    --include-tags --filter="tags:$(cat ./version)")
echo $IMAGE
```

The result of the above command should look something like this: 

```shell
us-west1-docker.pkg.dev/project/ws-images/ws-go-code@sha256:2d0f7ece95fe0ca83103602230f65d63c1950870bdd135c9b7c82256afc21d78
```

> Note, if the above command did not result in the URI of an image, navigate to the [debug](#debug) section to check on the status of your build process. 

Finally, create the workstation configuration: 

```shell
gcloud beta workstations configs create $WS_NAME-config \
    --project=$PROJECT_ID \
    --region=$REGION \
    --cluster=$WS_NAME-cluster \
    --container-custom-image=$IMAGE \
    --service-account=$RUNNER_SA \
    --machine-type=e2-standard-8 \
    --pd-disk-type=pd-ssd \
    --pd-disk-size=200 \
    --idle-timeout=14400 \
    --running-timeout=14400 \
    --pool-size=2
```

> Note: this process will take ~1 min.

### workstation 

With the cluster and configuration created, the last step is the actual workstation:

```shell
gcloud beta workstations create $WS_NAME-workstation \
    --project=$PROJECT_ID \
    --region=$REGION \
    --cluster=$WS_NAME-cluster \
    --config=$WS_NAME-config
```

At this point you should be able to `start` and `launch` the newly created workstation

```shell
open https://console.cloud.google.com/workstations/list?project=$PROJECT_ID
```

## updates

Now, as you edit the included [Dockerfile](./Dockerfile) to add tools or change versions, or define new user configuration options in [setup](assets/setup), simply create a git tag (`make tag`) to trigger new release. New image will be built, and the above created Cloud Workstations configuration will be automatically updated.

> Note: if the workstation is already running you will have to stop and start it again for the new image to take effect.

### user config options 

Any configuration you make in the user directory in the Dockerfile will be overwritten by Cloud Workstations when it dynamically attaches persistent disk backing each user's home directory at runtime. 

So any configuration you want to enable at the user-level, like configuring git or defining default VS Code settings will have to be done after launch. Still, there are way to make this process more consistent and easier to execute. 

In the [assets/setup](assets/setup) folder, your will find a couple of examples of these kinds of configurations:

* `git` - Sets up git configuration based on user input (available in workstation via `/setup/git`)
* `code` - Sets up common VS Code settings (available in workstation via `/setup/code`)

The user home settings will be persisted automatically by Cloud Workstations, even as you update the base image. Because of that aim for the setup scripts to be idempotent, so that they can be successfully applied whether this is the initial setup or an update. 

## debug

If you want to monitor or debug this process, start by navigating to the Cloud Build history tab and check on the status of your build. Both, `build` and `deploy` steps have to be green.

```shell
open https://console.cloud.google.com/cloud-build/builds;region=$REGION?project=$PROJECT_ID
```

Next, check whether the image is in the Artifact registry. You should see there a tag that equals to what was in [version](./version) during the last tag. 

```shell
open https://console.cloud.google.com/artifacts/docker/$PROJECT_ID/$REGION/$AR_REPO/ws-go-code?project=$PROJECT_ID
```

Finally, check the Configurations section of Cloud Workstations to see if the `config` was updated with the digest of the last built image that corresponds to the tag: 

```shell
open https://console.cloud.google.com/workstations/configurations?project=$PROJECT_ID
```

## schedule 

Vulnerabilities found in the image created by this pipeline will not not have a fix when you initially create this pipeline. If necessary, update the versions defined in the Dockerfile to the one where that vulnerability is fixed. To benefit however from upstream updates, you will have to setup a cron job that will rebuild the image on schedule.

To start, define manual trigger: 

```shell
gcloud beta builds triggers create manual \
    --name=custom-cloud-workstation-image-schedule \
    --project=$PROJECT_ID \
    --region=$REGION \
    --repo=https://github.com/$GH_USER/custom-cloud-workstation-image \
    --repo-type=GITHUB \
    --branch=main \
    --build-config=cloudbuild.yaml \
    --substitutions=_REPO=$AR_REPO,_CLUSTER=$WS_NAME-cluster,_CONFIG=$WS_NAME-config
```

Next, capture the trigger ID: 

```shell
export TRIGGER_ID=$(gcloud beta builds triggers describe \
    custom-cloud-workstation-image-schedule \
    --project=$PROJECT_ID \
    --region=$REGION \
    --format='value(id)')
```

You can run this trigger now manually, by invoking from `curl`. 

> This assumes that you have the necessary role to execute the build.

```shell
curl -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     "https://cloudbuild.googleapis.com/v1/projects/$PROJECT_ID/locations/$REGION/triggers/$TRIGGER_ID:run"
```

That means we can now set it up as a Cloud Schedule, first, make sure the Cloud Build account has sufficient rights to execute the job:: 


```shell
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
    --role="roles/cloudbuild.builds.editor" \
    --condition=None
```

Finally, create the Cloud Scheduler job:

```shell
gcloud scheduler jobs create http custom-cloud-workstation-image-schedule \
    --http-method POST \
    --schedule='0 1 * * *' \
    --location=$REGION \
    --uri=https://cloudbuild.googleapis.com/v1/projects/$PROJECT_ID/locations/$REGION/triggers/$TRIGGER_ID:run \
    --oauth-service-account-email=$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
    --oauth-token-scope=https://www.googleapis.com/auth/cloud-platform
```

Now everyday, at 1am UTC, the image will be rebuilt and the Cloud Workstation configuration updated with the latest image. 

## disclaimer

This is my personal project and it does not represent my employer. While I do my best to ensure that everything works, I take no responsibility for issues caused by this code.
# custom-cloud-workstation-image

Custom Google Cloud Workstations image pipeline.

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
# Cloud Workstations prefix
export WS_NAME="dev"
```

### image

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

To trigger an actual build of this image, first, update the [version](./version) file to the next canonical version, commit and push that change in git, and run `make tag`.

### workstation 

This section will overview the Cloud Workstation configuration to use the above created image: 

#### cluster 

To create a cluster: 

```shell
gcloud beta workstations clusters create $WS_NAME-cluster \
    --project=$PROJECT_ID \
    --region=$REGION \
    --async
```

This process can take as much as 20 min. Use the `describe` command to check on its status:

```shell
gcloud beta workstations clusters describe $WS_NAME-cluster \
    --project=$PROJECT_ID \
    --region=$REGION
```

The presence of `"reconciling": true` indicates that the cluster is still being provisioned. When complete, the response of the above command will look something like this: 

```json
{
  "createTime": "2023-04-08T22:34:52.290190289Z",
  "name": "projects/project/locations/us-west1/workstationClusters/ws-demo-cluster",
  "network": "projects/project/global/networks/default",
  "subnetwork": "projects/project/regions/us-west1/subnetworks/default",
  "updateTime": "2023-04-08T22:49:16.878931635Z"
}
```

#### config

Once the cluster is configured and the above `describe` command returns confirmation with `network` information, you are ready to create workstation configuration. To do this you will need some information. 

Start by getting the fully-qualified URI (with digest) of the image created by the above step:

```shell
export IMAGE=$(gcloud artifacts docker images list \
    us-docker.pkg.dev/$PROJECT_ID/$AR_REPO/ws-go-code \
    --format='value[separator="@"](IMAGE,DIGEST)' \
    --include-tags \
    --filter="tags:$(cat ./version)")
echo $IMAGE
```

Next, create a service account which will be used to run the workstation: 

```shell
gcloud iam service-accounts create $WS_NAME-workstation-runner
```

Export that account: 

```shell
export WS_RUNNER_SA="$WS_NAME-workstation-runner@$PROJECT_ID.iam.gserviceaccount.com"
```

At minimum, that service account has to have two roles: 

```shell
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$WS_RUNNER_SA" \
    --role="roles/workstations.workstationCreator" \
    --condition=None
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$WS_RUNNER_SA" \
    --role="roles/workstations.operationViewer" \
    --condition=None
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$WS_RUNNER_SA" \
    --role="roles/artifactregistry.reader" \
    --condition=None
```

Finally, create the workstation configuration: 

```shell
gcloud beta workstations configs create $WS_NAME-config \
    --project=$PROJECT_ID \
    --region=$REGION \
    --cluster=$WS_NAME-cluster \
    --container-custom-image=$IMAGE \
    --service-account=$WS_RUNNER_SA \
    --machine-type=e2-standard-8 \
    --pd-disk-type=pd-ssd \
    --pd-disk-size=200 \
    --idle-timeout=14400 \
    --running-timeout=14400 \
    --pool-size=2
```

> Note: this process will take ~1 min.

#### workstation 

Finally, with cluster and configuration created, the last step is the actual workstation:

```shell
gcloud beta workstations create dev-workstation \
    --project=$PROJECT_ID \
    --region=$REGION \
    --cluster=dev-cluster \
    --config=dev-config
```

At this point you should be able to `start` and `launch` the newly created workstation

```shell
open https://console.cloud.google.com/workstations/list?project=$PROJECT_ID
```

#### update

Whenever you build a new image, you can just update the config. Start by capturing the new image digest:

```shell
export IMAGE=$(gcloud artifacts docker images list \
    us-docker.pkg.dev/$PROJECT_ID/$AR_REPO/go-code \
    --format='value[separator="@"](IMAGE,DIGEST)' \
    --include-tags \
    --filter="tags:$(cat ./version)")
```

```shell
gcloud beta workstations configs update dev-config \
    --project=$PROJECT_ID \
    --region=$REGION \
    --cluster=dev-cluster \
    --container-custom-image=$IMAGE
```

> If the workstation is already running you will have to stop and start it again for the new image to take effect.

# disclaimer

This is my personal project and it does not represent my employer. While I do my best to ensure that everything works, I take no responsibility for issues caused by this code.
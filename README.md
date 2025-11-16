# custom-cloud-workstation-image

[GCP Cloud Workstations](https://cloud.google.com/workstations/docs/customize-container-images) provides number of [pre-configured base images](https://cloud.google.com/workstations/docs/customize-container-images) that include most of the common tools. You can extend these base images, or you can crete a custom image that has the minimal configuration for your specific use-case, and nothing else. 

This repo demonstrates how to create and use an optimized image for [Go](https://go.dev/) development in [VS Code](https://github.com/microsoft/vscode), with automatic Cloud Workstations configuration update. You can add your own tools in [Dockerfile](./Dockerfile), or provide additional user-specific options for new users in [setup](assets/setup) for things like VS Code default settings and git configuration. This pipeline includes new image build and workstation configuration update with that image.

## on time setup

> For brevity, these setup will skip the details for common steps, the assumption is you already are familiar with Cloud Build builds and Cloud Workstation configuration. A Terraform setup is coming soon for more automated deployment process.

```shell
export PROJECT_ID="proj-demo"      # GCP project ID
export REGION="us-west1"           # GCP region where you want to run the scans
export AR_REPO="ws-images"         # Artifact Registry name (us-west1-docker.pkg.dev/$PROJECT_ID/ws-images)
export WS_NAME="demo"              # Cloud Workstations prefix (helpful with multiple workstations)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
```

Next, create a service account which will be used to run the workstation: 

```shell
gcloud iam service-accounts create workstation-runner
```

Export accounts: 

```shell
export RUNNER_SA="workstation-runner@$PROJECT_ID.iam.gserviceaccount.com"
export BUILDER_SA="$PROJECT_NUMBER@cloudbuild.gserviceaccount.com"
export COMPUTE_SA="$PROJECT_NUMBER-compute@developer.gserviceaccount.com"
```

At minimum, the runner account has to have these roles. Depending on what you will do with this workstation, you may want to add additional roles.

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
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$COMPUTE_SA" \
    --role="roles/workstations.admin" \
    --condition=None
```

### registry    

Create Artifact Registry repository: 

```shell
gcloud artifacts repositories create $AR_REPO \
    --location=$REGION \
    --repository-format=docker
```

### network

Create a VPC network and subnet for the workstation cluster:

```shell
# Create VPC network
gcloud compute networks create $WS_NAME-network \
    --project=$PROJECT_ID \
    --subnet-mode=custom \
    --bgp-routing-mode=regional

# Create subnet in the specified region
gcloud compute networks subnets create $WS_NAME-subnet \
    --project=$PROJECT_ID \
    --region=$REGION \
    --network=$WS_NAME-network \
    --range=10.0.0.0/24
```

Export the network and subnet names for use in subsequent commands:

```shell
export NETWORK="$WS_NAME-network"
export SUBNET="$WS_NAME-subnet"
```

> Cloud Workstations automatically creates the necessary firewall rules for the control plane.

### cluster 

Create a workstation cluster in the network you just created:

> More info on the parameters available in this command [here](https://cloud.google.com/sdk/gcloud/reference/workstations/clusters/create)

```shell
gcloud workstations clusters create $WS_NAME-cluster \
    --project=$PROJECT_ID \
    --region=$REGION \
    --network="projects/$PROJECT_ID/global/networks/$NETWORK" \
    --subnetwork="projects/$PROJECT_ID/regions/$REGION/subnetworks/$SUBNET" \
    --async
```

You only have to run this once, but this process can take as much as 20 min. Use the `describe` command to check on its status:

```shell
gcloud workstations clusters describe $WS_NAME-cluster \
    --project=$PROJECT_ID \
    --region=$REGION
```

The presence of `"reconciling": true` indicates that the cluster **is still being provisioned**. When complete, the response of the above command will look something like this (notice `network` is now populated): 

```json
{
  "createTime": "2023-04-08T22:34:52.290190289Z",
  "name": "projects/my-project/locations/us-west1/workstationClusters/dev-cluster",
  "network": "projects/project/global/networks/default",
  "subnetwork": "projects/project/regions/us-west1/subnetworks/default",
  "updateTime": "2023-04-08T22:49:16.878931635Z"
}
```

### config

Once the cluster is configured and the above `describe` command returns confirmation with `network` information, create the workstation configuration with a base image. This initial configuration will be updated later by the Cloud Build pipeline.

> We're using the official Code OSS base image from Google as a starting point. The Cloud Build pipeline will update this configuration with your custom image after the build completes.

> **Note:** If you encounter an `enableAuditAgent` error with the stable `gcloud` command, update your gcloud CLI: `gcloud components update`

```shell
gcloud workstations configs create $WS_NAME-config \
    --project=$PROJECT_ID \
    --region=$REGION \
    --cluster=$WS_NAME-cluster \
    --container-custom-image=us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest \
    --service-account=$RUNNER_SA \
    --machine-type=n2-standard-8 \
    --pd-disk-type=pd-ssd \
    --pd-disk-size=200 \
    --idle-timeout=3600 \
    --running-timeout=43200
```

> Timeout settings: workstation stops after 1 hour of inactivity (`idle-timeout=3600`), but can run for up to 12 hours (`running-timeout=43200`) with active use (maximum allowed).

### image

Now build and deploy your custom image. The Cloud Build pipeline will automatically update the workstation configuration created above.

```shell
gcloud builds submit \
    --region=$REGION \
    --substitutions=_REGION=$REGION,_REPO=$AR_REPO,_CLUSTER=$WS_NAME-cluster,_CONFIG=$WS_NAME-config
```

After the build completes, the workstation configuration will be updated with your custom image.

### workstation 

With the cluster and configuration created, create the actual workstation:

```shell
gcloud workstations create $WS_NAME-workstation \
    --project=$PROJECT_ID \
    --region=$REGION \
    --cluster=$WS_NAME-cluster \
    --config=$WS_NAME-config
```

You can now start and launch your workstation:

```shell
open https://console.cloud.google.com/workstations/list?project=$PROJECT_ID
```

## updates

To update your custom image, simply submit a new build. The Cloud Build pipeline will automatically update the workstation configuration with the new image.

```shell
gcloud builds submit \
    --region=$REGION \
    --substitutions=_REGION=$REGION,_REPO=$AR_REPO,_CLUSTER=$WS_NAME-cluster,_CONFIG=$WS_NAME-config
```

> Note: If the workstation is running, you must stop and start it again for the new image to take effect.

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

## disclaimer

This is my personal project and it does not represent my employer. While I do my best to ensure that everything works, I take no responsibility for issues caused by this code.
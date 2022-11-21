# GCP IPAM Autopilot terraform module
GCP IPAM Autopilot terraform module will provision neccessary infrastructure to run GCP IPAM backend service.

It connects to Cloud Asset Inventory to also retrieve already existing subnets and ranges, in order to allow for a mixed usage.

Cloud Run service is configured to run [backend service](https://github.com/openx/gcp-ipam-autopilot) which provides a REST API. Once deployed [terraform provider](https://registry.terraform.io/providers/openx/gcp-ipam-autopilot) can be used to interact with backend.

## IPAM Autopilot Backend Service

The following GCP services are used as part of the deployment, and might cause cost:
  * [Cloud Run](https://cloud.google.com/run)
  * [CloudSQL](https://cloud.google.com/sql)
  * [Secret Manager](https://cloud.google.com/secret-manager)
  * [Cloud Asset Inventory](https://cloud.google.com/asset-inventory)

Optionally [Artifact Registry](https://cloud.google.com/artifact-registry) can be configured to host [container image](https://github.com/openx/gcp-ipam-autopilot) used by [Cloud Run](https://cloud.google.com/run) service.

You can also disable the automatic database migration using `DISABLE_DATABASE_MIGRATION` if you prefer to do the database migration manually. Therefore you have to set the value to `TRUE`. Or in Terraform use the `disable_database_migration` variable.

## Deploying

The terraform module takes the following variables, you can either set them via environment variables TF_VAR_<name> or in a .tfvars file.
| Variable                   	| Default Value   	| Description                                                                                                                                                	|
|----------------------------	|-----------------	|------------------------------------------------------------------------------------------------------------------------------------------------------------	|
| organization_id                 	|                 	| ID of the organization, that holds the subnets that are queried via Cloud Asset Inventory.
| project_id                 	|                 	| Project ID of the project to which the IPAM Autopilot should be deployed.                                                                                  	|
| region                     	| us-central1    	| GCP region that should contain the resources.                                                                                                              	|
| artifact_registry_location 	| us          	| Location for the Artifact Registry location, containing the Docker container image for the IPAM Autopilot backend.                                         	|
| artifact_registry_writers   	| []		|List of Service Accounts allowed to push container images to Artifact Registry	|
| artifact_registry_readers   	| ["allUsers"]		|List of users allowed to pull container images from Artifact Registry	|
| container_version          	| 2               	| Version of the container, since the container is build by the infrastructure automation, you can use this variable to trigger a new container image build. 	|
| ipam_container_image           	| us-docker.pkg.dev/ox-ipam-autopilot/ipam-autopilot/ipam-autopilot:latest           	| Specify alternative container image to be used by Cloud Run service |
| disable_database_migration           	| false           	| Whether the CloudRun service should automatically migrate the database |
| disable_org_level_cai_permissions    	| false           	| If service account running terraform lacks permissions on the org level it might be desirable not to attempt to grant CAI permissions on organizational level|

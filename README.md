# AVI Controller Deployment on GCP Terraform module
This Terraform module creates and configures an AVI (NSX Advanced Load-Balancer) Controller on GCP

## Module Functions
The module is meant to be modular and can create all or none of the prerequiste resources needed for the AVI GCP Deployment including:
* VPC and Subnet for the Controller (optional with create_networking variable)
* IAM Roles, Service Account, and Role Bindings (optional with create_iam variable)
* GCP Compute Image from the bucket controller file
* Firewall Rules for AVI Controller and SE communication
* GCP Compute Instance using the Controller Compute Image

During the creation of the Controller instance the following initialization steps are performed:
* Change default password to user specified password
* Copy Ansible playbook to controller using the assigned public IP
* Run Ansible playbook to configure initial settings and GCP Full Access Cloud 

# Environment Requirements
## Google Provider
For authenticating to GCP you must leverage either the "GOOGLE_APPLICATION_CREDENTIALS={{path}}" environment variable or use "gcloud auth application-default login"
## Controller Image
The AVI Controller image for GCP should be uploaded to a GCP Cloud Storage bucket before running this module with the path specified in the controller-image-gs-path variable. This can be done with the following gsutil commands:

```bash
gsutil mb <bucket>
gsutil -m cp ./gcp_controller-<avi-version>.tar.gz  gs://<bucket>/
```
## Host OS 
The following packages must be installed on the host operating system:
* curl 

## Usage
```hcl
module "avi_controller" {
  version = "1.0.x"

  region = "us-west1"
  create_networking = "true"
  create_iam = "false"
  controller_version = "20.1.3"
  service_account_email = "<sa-account>@<project>.iam.gserviceaccount.com"
  controller_default_password = ""
  controller_image_gs_path = "<bucket>/gcp_controller-20.1.3-9085.tar.gz"
  controller_password = "password"
  name_prefix = "avi"
  project = "gcp-project"
  vpc_network_name = "avi-vpc-network"
}
```
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13.6 |
| google | ~> 3.51.0 |

## Providers

| Name | Version |
|------|---------|
| google | ~> 3.51.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| avi\_subnet | The CIDR that will be used for creating a subnet in the AVI VPC | `string` | `"10.255.1.0/24"` | no |
| boot\_disk\_size | The boot disk size for the AVI controller | `number` | `128` | no |
| controller\_default\_password | This is the default password for the AVI controller image | `string` | n/a | yes |
| controller\_ha | If true a HA controller cluster is deployed | `bool` | `"false"` | no |
| controller\_image\_gs\_path | The Google Storage path to the GCP AVI Controller tar.gz image file using the bucket/filename syntax | `string` | n/a | yes |
| controller\_password | The password that will be used authenticating with the AVI Controller. This password be a minimum of 8 characters and contain at least one each of uppercase, lowercase, numbers, and special characters | `string` | n/a | yes |
| controller\_version | The AVI Controller version that will be deployed | `string` | n/a | yes |
| create\_iam | Create IAM Service Account, Roles, and Role Bindings for Avi GCP Full Access Cloud | `bool` | `"false"` | no |
| create\_networking | This variable controls the VPC and subnet creation for the AVI Controller. When set to false the custom-vpc-name and custom-subnetwork-name must be set. | `bool` | `"true"` | no |
| custom\_subnetwork\_name | This field can be used to specify an existing VPC subnetwork for the controller and SEs. The create-networking variable must also be set to false for this network to be used. | `string` | `null` | no |
| custom\_vpc\_name | This field can be used to specify an existing VPC for the controller and SEs. The create-networking variable must also be set to false for this network to be used. | `string` | `null` | no |
| machine\_type | The machine type used for the AVI Controller | `string` | `"n1-standard-8"` | no |
| name\_prefix | This prefix is appended to the names of the Controller and SEs | `string` | n/a | yes |
| network\_project | The GCP Network project | `string` | `""` | no |
| project | The project used for the AVI Controller | `string` | n/a | yes |
| region | The Region that the AVI controller and SEs will be deployed to | `string` | n/a | yes |
| server\_project | The backend server GCP Project | `string` | `""` | no |
| service\_account\_email | This is the service account email that will be leveraged by the AVI Controller. If the create-iam variable is true then this variable is not required | `string` | `""` | no |
| service\_engine\_project | The project used for AVI Service Engines | `string` | `""` | no |
| storage\_project | The storage project used for the AVI Controller Image | `string` | `""` | no |
| vip\_allocation\_strategy | The VIP allocation strategy for the GCP Cloud - ROUTES or ILB | `string` | `"ROUTES"` | no |

## Outputs

| Name | Description |
|------|-------------|
| avi\_controller\_public\_address | The public IP(s) of the AVI Controller |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
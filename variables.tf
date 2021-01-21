variable "region" {
  description = "The Region that the AVI controller and SEs will be deployed to"
  type        = string
}
variable "controller_ha" {
  description = "If true a HA controller cluster is deployed"
  type        = bool
  default     = "false"
}
variable "create_networking" {
  description = "This variable controls the VPC and subnet creation for the AVI Controller. When set to false the custom-vpc-name and custom-subnetwork-name must be set."
  type        = bool
  default     = "true"
}
variable "name_prefix" {
  description = "This prefix is appended to the names of the Controller and SEs"
  type        = string
}
variable "create_iam" {
  description = "Create IAM Service Account, Roles, and Role Bindings for Avi GCP Full Access Cloud"
  type        = bool
  default     = "false"
}
variable "controller_default_password" {
  description = "This is the default password for the AVI controller image"
  type        = string
  sensitive   = false
}
variable "service_account_email" {
  description = "This is the service account email that will be leveraged by the AVI Controller. If the create-iam variable is true then this variable is not required"
  type        = string
  default     = ""
}
variable "controller_version" {
  description = "The AVI Controller version that will be deployed"
  type        = string
}
variable "controller_image_gs_path" {
  description = "The Google Storage path to the GCP AVI Controller tar.gz image file using the bucket/filename syntax"
  type        = string
}
variable "boot_disk_size" {
  description = "The boot disk size for the AVI controller"
  type        = number
  default     = 128
}
variable "custom_vpc_name" {
  description = "This field can be used to specify an existing VPC for the controller and SEs. The create-networking variable must also be set to false for this network to be used."
  type        = string
  default     = null
}
variable "custom_subnetwork_name" {
  description = "This field can be used to specify an existing VPC subnetwork for the controller and SEs. The create-networking variable must also be set to false for this network to be used."
  type        = string
  default     = null
}
variable "machine_type" {
  description = "The machine type used for the AVI Controller"
  type        = string
  default     = "n1-standard-8"
}
variable "controller_password" {
  description = "The password that will be used authenticating with the AVI Controller. This password be a minimum of 8 characters and contain at least one each of uppercase, lowercase, numbers, and special characters"
  type        = string
  sensitive   = false
  validation {
    condition     = length(var.controller_password) > 7
    error_message = "The controller_password value must be more than 8 characters and contain at least one each of uppercase, lowercase, numbers, and special characters."
  }
}
variable "project" {
  description = "The project used for the AVI Controller"
  type        = string
}
variable "vip_allocation_strategy" {
  description = "The VIP allocation strategy for the GCP Cloud - ROUTES or ILB"
  type        = string
  default     = "ROUTES"

  validation {
    condition     = var.vip_allocation_strategy == "ROUTES" || var.vip_allocation_strategy == "ILB"
    error_message = "The vip_allocation_strategy value must be either ROUTES or ILB."
  }
}
variable "network_project" {
  description = "The GCP Network project"
  type        = string
  default     = ""
}
variable "service_engine_project" {
  description = "The project used for AVI Service Engines"
  type        = string
  default     = ""
}
variable "storage_project" {
  description = "The storage project used for the AVI Controller Image"
  type        = string
  default     = ""
}
variable "server_project" {
  description = "The backend server GCP Project"
  type        = string
  default     = ""
}
variable "avi_subnet" {
  description = "The CIDR that will be used for creating a subnet in the AVI VPC"
  type        = string
  default     = "10.255.1.0/24"
}
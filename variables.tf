variable "region" {
  description = "The Region that the Avi controller and SEs will be deployed to"
  type        = string
}
variable "project" {
  description = "The project used for the Avi Controller"
  type        = string
}
variable "avi_version" {
  description = "The version of Avi that will be deployed"
  type        = string
}
variable "controller_size" {
  description = "This value determines the number of vCPUs and memory allocated for the Avi Controller. Possible values are small, medium, or large."
  type        = string
  default     = "small"
  validation {
    condition     = contains(["small", "medium", "large"], var.controller_size)
    error_message = "Acceptable values are small, medium, or large."
  }
}
variable "configure_ipam_profile" {
  description = "Configure Avi IPAM Profile for Virtual Service Address Allocation. If set to true the virtualservice_network variable must also be set"
  type        = bool
  default     = "false"
}
variable "ipam_network" {
  description = "The Avi Network object created for Virtual Services. This CIDR should be unique to Avi and not overlap with a VPC CIDR. The vs_network_range variable must also be set. An example is 192.168.1.0/24"
  type        = string
  default     = ""
}
variable "ipam_network_range" {
  description = "A list of with the Network IP range for Virtual Services. An example is [\"192.168.1.10\", \"192.168.1.30\"]"
  type        = list(string)
  default     = [""]
}
variable "configure_dns_profile" {
  description = "Configure Avi DNS Profile for DNS Record Creation for Virtual Services. If set to true the dns_service_domain variable must also be set"
  type        = bool
  default     = "false"
}
variable "dns_service_domain" {
  description = "The DNS Domain that will be available for Virtual Services. Avi will be the Authorative Nameserver for this domain and NS records may need to be created pointing to the Avi Service Engine addresses. An example is demo.Avi.com"
  type        = string
  default     = ""
}
variable "configure_dns_vs" {
  description = "Create DNS Virtual Service. The configure_dns_profile and configure_ipam_profile variables must be set to true and their associated configuration variables must also be set"
  type        = bool
  default     = "false"
}
variable "name_prefix" {
  description = "This prefix is appended to the names of the Controller and SEs"
  type        = string
}
variable "controller_ha" {
  description = "If true a HA controller cluster is deployed and configured"
  type        = bool
  default     = "false"
}
variable "create_networking" {
  description = "This variable controls the VPC and subnet creation for the Avi Controller. When set to false the custom_vpc_name and custom_subnetwork_name must be set."
  type        = bool
  default     = "true"
}
variable "controller_public_address" {
  description = "This variable controls if the Controller has a Public IP Address. When set to false the Ansible provisioner will connect to the private IP of the Controller."
  type        = bool
  default     = "false"
}
variable "create_cloud_router" {
  description = "This variable is used to create a GCP Cloud Router when both the create_networking variable = true and the vip_allocation_strategy = ILB"
  type        = bool
  default     = "false"
}
variable "avi_subnet" {
  description = "The CIDR that will be used for creating a subnet in the Avi VPC"
  type        = string
  default     = "10.255.1.0/24"
}
variable "custom_vpc_name" {
  description = "This field can be used to specify an existing VPC for the controller and SEs. The create_networking variable must also be set to false for this network to be used."
  type        = string
  default     = null
}
variable "custom_subnetwork_name" {
  description = "This field can be used to specify an existing VPC subnetwork for the controller and SEs. The create_networking variable must also be set to false for this network to be used."
  type        = string
  default     = null
}
variable "create_iam" {
  description = "Create IAM Roles and Role Bindings necessary for the Avi GCP Full Access Cloud. If not set the Roles and permissions in this document must be associated with the controller service account - https://Avinetworks.com/docs/latest/gcp-full-access-roles-and-permissions/"
  type        = bool
  default     = "false"
}
variable "controller_default_password" {
  description = "This is the default password for the Avi controller image and can be found in the image download page."
  type        = string
  sensitive   = true
}
variable "controller_password" {
  description = "The password that will be used authenticating with the Avi Controller. This password be a minimum of 8 characters and contain at least one each of uppercase, lowercase, numbers, and special characters"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.controller_password) > 7
    error_message = "The controller_password value must be more than 8 characters and contain at least one each of uppercase, lowercase, numbers, and special characters."
  }
}
variable "service_account_email" {
  description = "This is the service account that will be leveraged by the Avi Controller. If the create-iam variable is true then this module will create the necessary custom roles and bindings for the SA"
  type        = string
}
variable "controller_image_gs_path" {
  description = "The Google Storage path to the GCP Avi Controller tar.gz image file using the bucket/filename syntax"
  type        = string
}
variable "custom_machine_type" {
  description = "This value overides the machine type used for the Avi Controller"
  type        = string
  default     = ""
}
variable "boot_disk_size" {
  description = "The boot disk size for the Avi controller"
  type        = number
  default     = 128
  validation {
    condition     = var.boot_disk_size >= 128
    error_message = "The Controller boot disk size should be greater than or equal to 128 GB."
  }
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
  description = "The GCP Network project that the Controller and SEs will use. If not set the project variable will be used"
  type        = string
  default     = ""
}
variable "service_engine_project" {
  description = "The project used for Avi Service Engines. If not set the project variable will be used"
  type        = string
  default     = ""
}
variable "storage_project" {
  description = "The storage project used for the Avi Controller Image. If not set the project variable will be used"
  type        = string
  default     = ""
}
variable "server_project" {
  description = "The backend server GCP Project. If not set the project variable will be used"
  type        = string
  default     = ""
}
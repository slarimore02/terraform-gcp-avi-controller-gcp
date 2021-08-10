variable "project" {
  description = "The project used for the Avi Controller"
  type        = string
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
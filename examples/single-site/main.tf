terraform {
  required_version = ">= 0.13.6"
  backend "local" {
  }
}
module "avi_controller_gcp" {
  source = "../.."

  region                      = var.region
  project                     = var.project
  create_networking           = var.create_networking
  create_iam                  = var.create_iam
  controller_default_password = var.controller_default_password
  avi_version                 = var.avi_version
  service_account_email       = var.service_account_email
  controller_image_gs_path    = var.controller_image_gs_path
  controller_password         = var.controller_password
  name_prefix                 = var.name_prefix
  controller_ha               = var.controller_ha
  controller_public_address   = var.controller_public_address
}

terraform {
  required_version = ">= 0.13.6"
  backend "local" {
  }
}
module "avi_controller_gcp" {
  source = "../.."

  region                      = "us-west1"
  project                     = var.project
  create_networking           = "true"
  create_iam                  = "false"
  controller_default_password = var.controller_default_password
  avi_version                 = "20.1.6"
  service_account_email       = var.service_account_email
  controller_image_gs_path    = var.controller_image_gs_path
  controller_password         = var.controller_password
  name_prefix                 = "terraform1"
}

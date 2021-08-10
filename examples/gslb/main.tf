terraform {
  required_version = ">= 0.13.6"
  backend "local" {
  }
}
module "avi_controller_east" {
  source = "../.."

  region                      = "us-east1"
  create_networking           = "false"
  custom_vpc_name             = "tf-vpc"
  custom_subnetwork_name      = "tf-subnet-east-1"
  create_iam                  = "false"
  avi_version                 = "20.1.6"
  controller_public_address   = "true"
  service_account_email       = var.service_account_email
  controller_ha               = "true"
  controller_default_password = var.controller_default_password
  controller_image_gs_path    = var.controller_image_gs_path
  controller_password         = var.controller_password
  name_prefix                 = "tf1east"
  project                     = var.project
  configure_ipam_profile      = "true"
  ipam_networks               = [{ network = "192.168.252.0/24", static_pool = ["192.168.252.10", "192.168.252.100"] }]
  configure_dns_profile       = "true"
  dns_service_domain          = "avieast.local"
  configure_dns_vs            = "true"
}
module "avi_controller_west" {
  source = "../.."

  region                          = "us-west1"
  create_networking               = "false"
  custom_vpc_name                 = "tf-vpc"
  custom_subnetwork_name          = "tf-subnet-west-1"
  create_iam                      = "false"
  avi_version                     = "20.1.6"
  controller_public_address       = "true"
  service_account_email           = var.service_account_email
  controller_ha                   = "true"
  controller_default_password     = var.controller_default_password
  controller_image_gs_path        = var.controller_image_gs_path
  controller_password             = var.controller_password
  name_prefix                     = "tf1west"
  project                         = var.project
  configure_ipam_profile          = "true"
  ipam_networks                   = [{ network = "192.168.251.0/24", static_pool = ["192.168.251.10", "192.168.251.100"] }]
  configure_dns_profile           = "true"
  dns_service_domain              = "aviwest.local"
  configure_dns_vs                = "true"
  configure_gslb                  = "true"
  gslb_site_name                  = "West1"
  gslb_domains                    = ["avigslb.local"]
  configure_gslb_additional_sites = "true"
  additional_gslb_sites           = [{ name = "East1", ip_address = module.avi_controller_east.controllers[0].private_ip_address, dns_vs_name = "DNS-VS" }]
}

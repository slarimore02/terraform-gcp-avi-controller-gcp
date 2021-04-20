terraform {
  required_version = ">= 0.13.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.58.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.0.0"
    }
  }
}
provider "google" {
  project = var.project
  region  = var.region
}
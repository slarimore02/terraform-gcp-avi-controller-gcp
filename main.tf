terraform {
  required_version = ">= 0.12.21"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.51.0"
    }
  }
}
provider "google" {
  project = var.project
  region  = var.region
}


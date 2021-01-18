resource "google_compute_firewall" "avi_controller_mgmt" {
  name    = "avi-controller-mgmt"
  project = var.network_project != "" ? var.network_project : var.project
  network = var.vpc_network_name

  allow {
    protocol = "tcp"
    ports    = ["22", "443", "5054"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["avi-controller"]
  depends_on    = [google_compute_network.vpc_network]
}

resource "google_compute_firewall" "avi_controller_to_controller" {
  name    = "avi-controller-to-controller"
  project = var.network_project != "" ? var.network_project : var.project
  network = var.vpc_network_name

  allow {
    protocol = "tcp"
    ports    = ["22", "443", "8443"]
  }

  source_tags = ["avi-controller"]
  target_tags = ["avi-controller"]
  depends_on  = [google_compute_network.vpc_network]
}

resource "google_compute_firewall" "avi_se_to_se" {
  name    = "avi-se-to-se"
  project = var.network_project != "" ? var.network_project : var.project
  network = var.vpc_network_name

  allow {
    protocol = 75
  }

  allow {
    protocol = 97
  }

  allow {
    protocol = "udp"
    ports    = ["1550"]
  }

  source_tags = ["avi-se"]
  target_tags = ["avi-se"]
  depends_on  = [google_compute_network.vpc_network]
}

resource "google_compute_firewall" "avi_se_mgmt" {
  name    = "avi-se-mgmt"
  project = var.network_project != "" ? var.network_project : var.project
  network = var.vpc_network_name

  allow {
    protocol = "udp"
    ports    = ["123"]
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "8443"]
  }

  source_tags = ["avi-se"]
  target_tags = ["avi-controller"]
  depends_on  = [google_compute_network.vpc_network]
}

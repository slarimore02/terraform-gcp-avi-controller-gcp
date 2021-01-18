locals {
  # Controller Settings used as Ansible Variables
  cloud_settings = {
    se_vpc_network_name     = var.create_networking ? google_compute_network.vpc_network[0].name : var.custom_vpc_name
    se_mgmt_subnet_name     = var.create_networking ? google_compute_subnetwork.avi[0].name : var.custom_subnetwork_name
    vpc_project_id          = var.network_project != "" ? var.network_project : var.project
    controller_version      = var.controller_version
    region                  = var.region
    se_project_id           = var.service_engine_project != "" ? var.service_engine_project : var.project
    se_name_prefix          = var.name_prefix
    se_mgmt_tag             = google_compute_firewall.avi_se_mgmt.name
    se_data_tag             = google_compute_firewall.avi_se_to_se.name
    vip_allocation_strategy = var.vip_allocation_strategy
    zones                   = data.google_compute_zones.available.names
  }
}
resource "google_compute_instance" "avi_controller" {
  count        = var.controller_ha ? 3 : 1
  name         = "${var.name_prefix}-avi-controller-${count.index + 1}"
  machine_type = var.machine_type
  zone         = data.google_compute_zones.available.names[count.index]

  tags = ["avi-controller"]

  boot_disk {
    initialize_params {
      image = google_compute_image.controller.name
      size  = var.boot_disk_size
    }
  }

  network_interface {
    subnetwork = var.create_networking ? google_compute_subnetwork.avi[0].name : var.custom_subnetwork_name
    access_config {
    }
  }

  service_account {
    email  = var.create_iam ? google_service_account.avi_service_account[0].email : var.service_account_email
    scopes = ["cloud-platform"]
  }
  provisioner "local-exec" {
    command = "bash ${path.module}/files/change-controller-password.sh --controller-address \"${self.network_interface[0].access_config[0].nat_ip}\" --current-password \"${var.controller_default_password}\" --new-password \"${var.controller_password}\""
  }
  provisioner "file" {
    connection {
      type     = "ssh"
      host     = self.network_interface[0].access_config[0].nat_ip
      user     = "admin"
      timeout  = "600s"
      password = var.controller_password
    }
    content = templatefile("${path.module}/files/avi-controller-gcp-all-in-one-play.yml.tpl",
    local.cloud_settings)
    destination = "/home/admin/avi-controller-gcp-all-in-one-play.yml"
  }
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      host     = self.network_interface[0].access_config[0].nat_ip
      user     = "admin"
      timeout  = "600s"
      password = var.controller_password
    }
    inline = [
      "ansible-playbook avi-controller-gcp-all-in-one-play.yml -e password=${var.controller_password} > ansible-playbook.log 2> ansible-error.log",
      "echo Controller Configuration Completed"
    ]
  }
  depends_on = [google_compute_image.controller]
}

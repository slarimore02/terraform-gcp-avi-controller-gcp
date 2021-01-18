resource "google_compute_image" "controller" {
  name = "avi-controller-${replace(var.controller_version, ".", "-")}"

  raw_disk {
    source = "https://storage.googleapis.com/${var.controller_image_gs_path}"
  }
}
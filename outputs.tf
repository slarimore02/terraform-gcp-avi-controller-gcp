output "controller_address" {
  description = "The IP Address(es) of the AVI Controller(s)"
  value       = var.controller_public_address ? [for s in google_compute_instance.avi_controller : s.network_interface[0].access_config[0].nat_ip] : [for s in google_compute_instance.avi_controller : s.network_interface[0].network_ip]
}
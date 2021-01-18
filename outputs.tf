#output "gcp-zone" {
#    value = data.google_compute_zones.available
#}
#output "subnetworks" {
#    value = google_compute_subnetwork.avi
#}
output "avi_controller_public_address" {
  description = "The public IP(s) of the AVI Controller"
  value       = [for s in google_compute_instance.avi_controller : s.network_interface[0].access_config[0].nat_ip]
}
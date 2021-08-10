output "controller_address" {
  description = "Avi Controller IP Address"
  value       = module.avi_controller_gcp.controllers
}
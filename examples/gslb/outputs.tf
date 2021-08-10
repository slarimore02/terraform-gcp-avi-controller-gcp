output "west_controller_ip" {
  description = "IP address for the West region controller"
  value       = module.avi_controller_west.controllers
}
output "east_controller_ip" {
  description = "IP address for the East region controller"
  value       = module.avi_controller_east.controllers
}
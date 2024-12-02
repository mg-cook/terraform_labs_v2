output "gateway_frontend_ip" {
  value = "http://${module.networking.public_ip_address}"
}

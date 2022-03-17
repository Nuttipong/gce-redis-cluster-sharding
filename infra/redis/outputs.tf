output "result" {
  sensitive = false  
  value = {
    instances  = google_compute_instance.instances[*].network_interface.0.access_config.0.nat_ip,
    # replicas = google_compute_instance.replicas[*].network_interface[*].access_config.0.nat_ip
  }
}
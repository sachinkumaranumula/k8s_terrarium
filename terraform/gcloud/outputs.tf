output "hosts" {
  value = {
    (google_compute_instance_from_template.k8s_cp1.network_interface.0.network_ip)     = google_compute_instance_from_template.k8s_cp1.name
    (google_compute_instance_from_template.k8s_worker1.network_interface.0.network_ip) = google_compute_instance_from_template.k8s_worker1.name
  }
}
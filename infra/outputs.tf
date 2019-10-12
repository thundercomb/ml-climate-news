output "gke_cluster_name" {
  value = google_container_cluster.primary.name
}

output "gke_cluster_ip" {
  value = google_container_cluster.primary.endpoint
}

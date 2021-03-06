resource "google_container_cluster" "primary" {
  name     = "primary-gke-cluster"
  location = var.region
  project  = var.project

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  depends_on = [google_project_service.climate_analytics]
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "primary-node-pool"
  location   = var.region
  project    = var.project
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "n1-standard-4"
    disk_size_gb = 100

    metadata = {
      disable-legacy-endpoints  = "true"
      default_max_pods_per_node = 110
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/bigquery",
      "https://www.googleapis.com/auth/devstorage.read_write",
    ]
  }

  depends_on = [google_container_cluster.primary]
}

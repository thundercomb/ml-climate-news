# This is for prepping some infra for kubeflow in advanced
# Kubeflow only gets installed after terraform has run

resource "google_storage_bucket" "kubeflow_pipeline_bucket" {
  name               = "kubeflow-pipeline-bucket"
  project            = var.project
  location           = "EU"
  bucket_policy_only = true
}

resource "google_project_iam_binding" "gke_kubeflow_jupyter_storage" {
  project = var.project
  role    = "roles/storage.admin"

  members = [
    "serviceAccount:${google_project.climate_analytics.number}-compute@developer.gserviceaccount.com"
  ]

  depends_on = [google_project_service.climate_analytics,
  google_container_cluster.primary]
}


resource "google_project_iam_binding" "gke_kubeflow_jupyter_bigquery" {
  project = var.project
  role    = "roles/bigquery.admin"

  members = [
    "serviceAccount:${google_project.climate_analytics.number}-compute@developer.gserviceaccount.com"
  ]

  depends_on = [google_project_service.climate_analytics,
  google_container_cluster.primary]
}

# The firewall rules are for Kubeflow Istio, which is setup later
# If the ports change, this will need changing too

resource "google_compute_firewall" "http_istio_ingress" {
  name    = "allow-gateway-http"
  network = "default"
  project = var.project

  allow {
    protocol = "tcp"
    ports    = ["31380"]
  }
}

resource "google_compute_firewall" "https_istio_ingress" {
  name    = "allow-gateway-https"
  network = "default"
  project = var.project

  allow {
    protocol = "tcp"
    ports    = ["31390"]
  }
}

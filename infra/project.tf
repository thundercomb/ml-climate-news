resource "google_project" "climate_analytics" {
  name            = var.project
  project_id      = var.project
  billing_account = var.billing_account
}

resource "google_project_services" "climate_analytics" {
  project = var.project
  services = [
    "logging.googleapis.com",
    "bigquery-json.googleapis.com",
    "appengine.googleapis.com",
    "pubsub.googleapis.com",
    "sourcerepo.googleapis.com",
    "cloudbuild.googleapis.com",
    "containerregistry.googleapis.com",
    "storage-api.googleapis.com",
    "bigquerystorage.googleapis.com"
  ]

  depends_on = ["google_project.climate_analytics"]
}

resource "google_project_iam_binding" "cloud_build_app_engine" {
  project = var.project
  role    = "roles/appengine.appAdmin"

  members = [
    "serviceAccount:${google_project.climate_analytics.number}@cloudbuild.gserviceaccount.com"
  ]

  depends_on = ["google_project_services.climate_analytics"]
}

resource "google_project_iam_binding" "editors" {
  project = var.project
  role    = "roles/editor"

  members = [
    "serviceAccount:service-${google_project.climate_analytics.number}@containerregistry.iam.gserviceaccount.com",
    "serviceAccount:${google_project.climate_analytics.project_id}@appspot.gserviceaccount.com"
  ]

  depends_on = ["google_project_services.climate_analytics"]
}

resource "google_project_iam_binding" "app_engine_bigquery" {
  project = var.project
  role    = "roles/bigquery.dataEditor"

  members = [
    "serviceAccount:${google_project.climate_analytics.project_id}@appspot.gserviceaccount.com"
  ]

  depends_on = ["google_project_services.climate_analytics"]
}

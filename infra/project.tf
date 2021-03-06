resource "google_project" "climate_analytics" {
  name            = var.project
  project_id      = var.project
  billing_account = var.billing_account
}

resource "google_project_service" "climate_analytics" {
  project = var.project
  for_each = {
    "logging.googleapis.com"           = "",
    "bigquery.googleapis.com"          = "",
    "appengine.googleapis.com"         = "",
    "pubsub.googleapis.com"            = "",
    "sourcerepo.googleapis.com"        = "",
    "cloudbuild.googleapis.com"        = "",
    "containerregistry.googleapis.com" = "",
    "storage-api.googleapis.com"       = "",
    "bigquerystorage.googleapis.com"   = "",
    "container.googleapis.com"         = "",
    "compute.googleapis.com"           = "",
    "oslogin.googleapis.com"           = "",
    "iam.googleapis.com"               = "",
    "iamcredentials.googleapis.com"    = ""
  }
  service = each.key

  depends_on = [google_project.climate_analytics]
}

resource "google_app_engine_application" "app" {
  project     = google_project.climate_analytics.project_id
  location_id = var.region
}

resource "google_project_iam_binding" "cloud_build_app_engine" {
  project = var.project
  role    = "roles/appengine.appAdmin"

  members = [
    "serviceAccount:${google_project.climate_analytics.number}@cloudbuild.gserviceaccount.com"
  ]

  depends_on = [google_project_service.climate_analytics]
}

resource "google_project_iam_binding" "editors" {
  project = var.project
  role    = "roles/editor"

  members = [
    "serviceAccount:service-${google_project.climate_analytics.number}@containerregistry.iam.gserviceaccount.com",
    "serviceAccount:${google_project.climate_analytics.project_id}@appspot.gserviceaccount.com",
    "serviceAccount:${google_project.climate_analytics.number}@cloudservices.gserviceaccount.com",
  ]

  depends_on = [google_project_service.climate_analytics,
  google_app_engine_application.app]
}

resource "google_project_iam_binding" "app_engine_bigquery" {
  project = var.project
  role    = "roles/bigquery.dataEditor"

  members = [
    "serviceAccount:${google_project.climate_analytics.project_id}@appspot.gserviceaccount.com"
  ]

  depends_on = [google_project_service.climate_analytics,
  google_app_engine_application.app]
}

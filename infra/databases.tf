resource "google_pubsub_topic" "climate_analytics" {
  for_each = var.topics
  name     = each.value
  project  = var.project

  depends_on = [google_project_service.climate_analytics]
}

resource "google_pubsub_subscription" "climate_analytics" {
  for_each = var.subscriptions
  name     = each.value
  project  = var.project
  topic    = google_pubsub_topic.climate_analytics[each.key].name

  depends_on = [google_pubsub_topic.climate_analytics]
}

resource "google_bigquery_dataset" "climate_analytics" {
  for_each      = var.datasets
  dataset_id    = each.value
  friendly_name = each.value
  project       = var.project
  location      = "EU"

  labels = {
    env = "default"
  }

  access {
    role          = "OWNER"
    user_by_email = var.owner_email
  }

  access {
    role          = "WRITER"
    user_by_email = "${google_project.climate_analytics.number}@cloudbuild.gserviceaccount.com"
  }

  depends_on = [google_project_service.climate_analytics]
}

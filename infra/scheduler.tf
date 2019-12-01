resource "google_cloud_scheduler_job" "ingest_clnn" {
  name        = "ingest-clnn"
  project     = var.project
  region      = var.region
  description = "ingest clnn daily news"
  schedule    = "0 8 * * *"
  time_zone   = "Europe/London"

  http_target {
    http_method = "GET"
    uri         = "https://ingest-clnn-news-dot-${var.project}.appspot.com/ingest"
  }
}

resource "google_cloud_scheduler_job" "ml_generate_climate_news" {
  name        = "generate-climate-news"
  project     = var.project
  region      = var.region
  description = "generate daily climate news"
  schedule    = "0 9 * * *"
  time_zone   = "Europe/London"

  http_target {
    http_method = "POST"
    uri         = "https://cloudbuild.googleapis.com/v1/projects/${var.project}/triggers/BUILD-ml-generate-climate-news-image:run"
    body        = base64encode("{\"branch\":\"master\"}")

    oauth_token {
      service_account_email = "${var.project}@appspot.gserviceaccount.com"
    }
  }
}

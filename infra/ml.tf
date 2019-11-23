# This is for prepping some infra for kubeflow in advanced
# Kubeflow only gets installed after terraform has run

resource "google_storage_bucket" "ml_models_bucket" {
  name               = "${var.ml_models_bucket}"
  project            = "${var.project}"
  location           = "EU"
  bucket_policy_only = true
}

resource "google_storage_bucket" "ml_articles_bucket" {
  name               = "${var.ml_articles_bucket}"
  project            = "${var.project}"
  location           = "EU"
  bucket_policy_only = true
}

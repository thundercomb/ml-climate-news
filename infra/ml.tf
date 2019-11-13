# This is for prepping some infra for kubeflow in advanced
# Kubeflow only gets installed after terraform has run

resource "google_storage_bucket" "kubeflow_pipeline_bucket" {
  name               = "${var.ml_models_bucket}"
  project            = "${var.project}"
  location           = "EU"
  bucket_policy_only = true
}

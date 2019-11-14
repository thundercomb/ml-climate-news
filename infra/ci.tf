resource "google_sourcerepo_repository" "ci_climate_analytics" {
  for_each = var.ml_repos
  name     = each.value
  project  = var.project

  depends_on = ["google_project_services.climate_analytics"]
}

resource "google_cloudbuild_trigger" "ci_climate_analytics" {
  for_each = var.ml_repos
  project  = var.project

  trigger_template {
    branch_name = "master"
    repo_name   = each.value
  }

  description = "BUILD: ${each.value} image"
  filename    = "cloudbuild.yaml"
  included_files = [
    "*"
  ]

  depends_on = ["google_sourcerepo_repository.ci_climate_analytics"]
}

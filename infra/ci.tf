resource "google_sourcerepo_repository" "climate_analytics" {
  for_each = var.repos
  name     = each.value
  project  = var.project

  depends_on = ["google_project_services.climate_analytics"]
}

resource "google_cloudbuild_trigger" "climate_analytics" {
  for_each = var.repos
  project  = var.project

  trigger_template {
    branch_name = "master"
    repo_name   = each.value
  }

  description = "DEPLOY: ${each.value} service"
  filename    = "cloudbuild.yaml"
  included_files = [
    "*"
  ]

  depends_on = ["google_sourcerepo_repository.climate_analytics"]
}

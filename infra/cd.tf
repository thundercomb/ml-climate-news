resource "google_sourcerepo_repository" "cd_climate_analytics" {
  for_each = var.app_repos
  name     = each.value
  project  = var.project

  depends_on = ["google_project_services.climate_analytics"]
}

resource "google_cloudbuild_trigger" "cd_climate_analytics" {
  for_each = var.app_repos
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

  depends_on = ["google_sourcerepo_repository.cd_climate_analytics"]
}

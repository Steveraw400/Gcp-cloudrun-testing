# Enable Cloud Run API
resource "google_project_service" "run_api" {
  service = "run.googleapis.com"
}

# Cloud Run Service
resource "google_cloud_run_v2_service" "landing_page" {
  name     = "my-landing-page"
  location = var.region

  template {
    containers {
      image = var.container_image
      ports {
        container_port = 8080
      }
    }
  }

  depends_on = [google_project_service.run_api]
}

# Allow public access
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  project  = google_cloud_run_v2_service.landing_page.project
  location = google_cloud_run_v2_service.landing_page.location
  name     = google_cloud_run_v2_service.landing_page.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}


data "google_project" "project" {}

resource "google_project_iam_member" "artifact_registry_reader" {
  project = data.google_project.project.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = "my-repo"
  format        = "DOCKER"
}
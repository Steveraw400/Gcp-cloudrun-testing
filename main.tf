# Enable Cloud Run API
resource "google_project_service" "run_api" {
  service = "run.googleapis.com"
}

# Cloud Run Service
resource "google_cloud_run_service" "landing_page" {
  name     = "my-landing-page"
  location = var.region

  template {
    spec {
      containers {
        image = var.container_image
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [google_project_service.run_api]
}

# Allow public access
resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_service.landing_page.name
  location = google_cloud_run_service.landing_page.location
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
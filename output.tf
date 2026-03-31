output "service_url" {
  description = "Cloud Run URL"
  value       = google_cloud_run_service.landing_page.status[0].url
}
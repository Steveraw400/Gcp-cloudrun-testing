variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}



variable "container_image" {
  default = "gcr.io/rawson-devops-project/landing-page:latest"
}
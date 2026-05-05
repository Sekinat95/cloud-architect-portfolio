variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "mlops-pipeline-inference-only"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "europe-west2"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "europe-west2-a"
}
variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "rag-pipeline-501417"
}

variable "region" {
  description = "Default region for regional resources"
  type        = string
  default     = "europe-west2"
}

variable "zone" {
  description = "Default zone for zonal resources"
  type        = string
  default     = "europe-west2-a"
}

variable "name_prefix" {
  description = "Prefix applied to resource names"
  type        = string
  default     = "rag-pipeline-501417"
}

variable "ingestion_bucket_name" {
  description = "Name of the bucket that holds raw source documents (separate from the Terraform state bucket)"
  type        = string
  default     = "rag-pipeline-501417-ingestion"
}

variable "db_tier" {
  description = "Cloud SQL machine tier. db-f1-micro is the cheapest shared-core option, fine for a POC."
  type        = string
  default     = "db-f1-micro"
}

variable "db_name" {
  description = "Name of the Postgres database created on the instance"
  type        = string
  default     = "ragdb"
}

variable "db_user" {
  description = "Postgres user for the pipeline"
  type        = string
  default     = "rag_pipeline"
}
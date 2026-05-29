# Cloud Build trigger created manually in console due to GitHub App
# regional mapping requirement — see ADR-004.

# Cloud Scheduler — triggers pipeline run every Monday at 08:00 UTC
resource "google_cloud_scheduler_job" "pipeline_schedule" {
  name      = "finbert-pipeline-weekly"
  region    = var.region
  schedule  = "0 8 * * 1"
  time_zone = "UTC"

  http_target {
    http_method = "POST"
    uri         = "https://europe-west2-aiplatform.googleapis.com/v1/projects/${var.project_id}/locations/${var.region}/pipelineJobs"

    body = base64encode(jsonencode({
      displayName  = "finbert-scheduled-run"
      templateUri  = "gs://inference-pipeline-w-eleventts-pipeline-root/compiled/pipeline.yaml"
      pipelineRoot = "gs://inference-pipeline-w-eleventts-pipeline-root"
    }))

    headers = {
      "Content-Type" = "application/json"
    }

    oauth_token {
      service_account_email = google_service_account.pipeline_sa.email
    }
  }

  depends_on = [time_sleep.wait_for_apis]
}

# ── Source VM Service Account ─────────────────────────────────

resource "google_service_account" "source_vm_sa" {
  account_id   = "source-vm-sa"
  display_name = "Source VM Service Account"
}

resource "google_project_iam_member" "vm_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.source_vm_sa.email}"
}

resource "google_project_iam_member" "vm_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.source_vm_sa.email}"
}

# ── DMS Service Account ───────────────────────────────────────

resource "google_service_account" "dms_sa" {
  account_id   = "dms-migration-sa"
  display_name = "DMS Migration Service Account"
}

resource "google_project_iam_member" "dms_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.dms_sa.email}"
}

resource "google_project_iam_member" "dms_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.dms_sa.email}"
}

# ── DMS Service Agent ─────────────────────────────────────────
# GCP creates this service account automatically when DMS API
# is enabled. We only need to grant it the required role.

resource "google_project_iam_member" "dms_service_agent" {
  project = var.project_id
  role    = "roles/datamigration.serviceAgent"
  member  = "serviceAccount:service-${var.project_number}@gcp-sa-datamigration.iam.gserviceaccount.com"
}
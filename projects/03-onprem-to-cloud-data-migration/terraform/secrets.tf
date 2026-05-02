resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "google_secret_manager_secret" "db_password" {
  secret_id = "postgres-migration-password"

  replication {
    auto {}
  }

  depends_on = [time_sleep.wait_for_apis]
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

data "google_secret_manager_secret_version" "db_password" {
  secret  = google_secret_manager_secret.db_password.id
  version = "latest"

  depends_on = [google_secret_manager_secret_version.db_password]
}
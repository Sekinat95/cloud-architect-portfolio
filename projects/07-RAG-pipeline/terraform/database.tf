resource "random_password" "db_password" {
  length  = 24
  special = true
}

resource "google_sql_database_instance" "rag_pg" {
  project             = var.project_id
  name                = "${var.name_prefix}-pg"
  region              = var.region
  database_version    = "POSTGRES_15"
  deletion_protection = false

  settings {
    tier = var.db_tier

    ip_configuration {
      ipv4_enabled = true

      authorized_networks {
        name  = "allow-all-temp-poc"
        value = "0.0.0.0/0"
      }
    }
  }

  depends_on = [google_project_service.sqladmin]
}

resource "google_sql_database" "rag_db" {
  project  = var.project_id
  name     = var.db_name
  instance = google_sql_database_instance.rag_pg.name
}

resource "google_sql_user" "rag_user" {
  project  = var.project_id
  name     = var.db_user
  instance = google_sql_database_instance.rag_pg.name
  password = random_password.db_password.result
}
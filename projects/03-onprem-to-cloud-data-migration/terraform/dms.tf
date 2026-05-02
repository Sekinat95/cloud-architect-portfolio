# ── Source Connection Profile ─────────────────────────────────
resource "google_database_migration_service_connection_profile" "source_profile" {
  location              = var.region
  connection_profile_id = "source-postgres-profile"

  postgresql {
    host     = google_compute_instance.source_vm.network_interface[0].network_ip
    port     = 5432
    username = "migration_user"
    password = data.google_secret_manager_secret_version.db_password.secret_data
  }

  depends_on = [
    time_sleep.wait_for_postgres,
    google_compute_vpn_tunnel.source_to_target,
    google_compute_vpn_tunnel.target_to_source
  ]
}

# ── Destination Connection Profile ────────────────────────────
resource "google_database_migration_service_connection_profile" "destination_profile" {
  location              = var.region
  connection_profile_id = "destination-cloudsql-profile"

  cloudsql {
    settings {
      database_version = "POSTGRES_15"
      tier             = "db-custom-2-4096"
      source_id        = "projects/${var.project_id}/locations/${var.region}/connectionProfiles/source-postgres-profile"

      ip_config {
        enable_ipv4     = false
        private_network = google_compute_network.target_vpc.id
      }
    }
  }

  lifecycle {
    ignore_changes = [display_name, cloudsql[0].settings[0].zone]
  }

  depends_on = [
    google_database_migration_service_connection_profile.source_profile
  ]
}
# Networking
output "source_vpc_id" {
  value = google_compute_network.source_vpc.id
}

output "target_vpc_id" {
  value = google_compute_network.target_vpc.id
}

output "source_router" {
  value = google_compute_router.source_router.name
}

output "target_router" {
  value = google_compute_router.target_router.name
}

# Compute
output "source_vm_name" {
  value = google_compute_instance.source_vm.name
}

output "source_vm_internal_ip" {
  value = google_compute_instance.source_vm.network_interface[0].network_ip
}

# IAM
output "dms_service_account" {
  value = google_service_account.dms_sa.email
}

output "source_vm_service_account" {
  value = google_service_account.source_vm_sa.email
}

# Secrets
output "db_password_secret_id" {
  value     = google_secret_manager_secret.db_password.secret_id
  sensitive = true
}

# DMS
output "destination_profile_id" {
  value = google_database_migration_service_connection_profile.destination_profile.connection_profile_id
}

output "source_profile_id" {
  value = google_database_migration_service_connection_profile.source_profile.connection_profile_id
}
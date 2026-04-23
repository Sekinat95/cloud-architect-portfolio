resource "google_compute_instance" "source_vm" {
  name         = "onprem-postgres-vm"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.source_subnet.id
    access_config {}
  }

  service_account {
    email  = google_service_account.source_vm_sa.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    startup-script = file("${path.module}/scripts/startup.sh")
    db-password    = data.google_secret_manager_secret_version.db_password.secret_data
  }

  tags = ["postgres-source"]

  depends_on = [
    time_sleep.wait_for_apis,
    google_service_account.source_vm_sa
  ]
}

resource "time_sleep" "wait_for_postgres" {
  depends_on      = [google_compute_instance.source_vm]
  create_duration = "120s"
}
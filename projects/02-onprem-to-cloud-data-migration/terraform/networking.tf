# ── Source VPC ────────────────────────────────────────────────

resource "google_compute_network" "source_vpc" {
  name                    = "source-vpc"
  auto_create_subnetworks = false
  depends_on              = [time_sleep.wait_for_apis]
}

resource "google_compute_subnetwork" "source_subnet" {
  name          = "source-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.source_vpc.id
}

# Allow PostgreSQL from target VPC only
resource "google_compute_firewall" "allow_postgres_inbound" {
  name    = "allow-postgres-inbound"
  network = google_compute_network.source_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_ranges = ["10.0.2.0/24"]
}

# Allow SSH via IAP
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh-source"
  network = google_compute_network.source_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
}

# Allow internal traffic within source VPC
resource "google_compute_firewall" "allow_internal_source" {
  name    = "allow-internal-source"
  network = google_compute_network.source_vpc.name

  allow { protocol = "tcp" }
  allow { protocol = "udp" }
  allow { protocol = "icmp" }

  source_ranges = ["10.0.1.0/24"]
}

# ── Target VPC ────────────────────────────────────────────────

resource "google_compute_network" "target_vpc" {
  name                    = "target-vpc"
  auto_create_subnetworks = false
  depends_on              = [time_sleep.wait_for_apis]
}

resource "google_compute_subnetwork" "target_subnet" {
  name          = "target-subnet"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.region
  network       = google_compute_network.target_vpc.id
}

# Allow internal traffic within target VPC
resource "google_compute_firewall" "allow_internal_target" {
  name    = "allow-internal-target"
  network = google_compute_network.target_vpc.name

  allow { protocol = "tcp" }
  allow { protocol = "udp" }
  allow { protocol = "icmp" }

  source_ranges = ["10.0.2.0/24"]
}

# Allow traffic from source VPC via VPN tunnel
resource "google_compute_firewall" "allow_from_source_vpc" {
  name    = "allow-from-source-vpc"
  network = google_compute_network.target_vpc.name

  allow { protocol = "tcp" }
  allow { protocol = "icmp" }

  source_ranges = ["10.0.1.0/24"]
}

# ── Private Service Access for Cloud SQL ──────────────────────

resource "google_compute_global_address" "private_service_access" {
  name          = "private-service-access"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.target_vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.target_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_access.name]
}
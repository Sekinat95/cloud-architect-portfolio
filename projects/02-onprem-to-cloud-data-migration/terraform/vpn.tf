# ── VPN Gateways ──────────────────────────────────────────────

resource "google_compute_vpn_gateway" "source_vpn_gateway" {
  name    = "source-vpn-gateway"
  network = google_compute_network.source_vpc.id
  region  = var.region
}

resource "google_compute_vpn_gateway" "target_vpn_gateway" {
  name    = "target-vpn-gateway"
  network = google_compute_network.target_vpc.id
  region  = var.region
}

# ── External IPs ──────────────────────────────────────────────

resource "google_compute_address" "source_vpn_ip" {
  name   = "source-vpn-ip"
  region = var.region
}

resource "google_compute_address" "target_vpn_ip" {
  name   = "target-vpn-ip"
  region = var.region
}

# ── Forwarding Rules — Source ─────────────────────────────────

resource "google_compute_forwarding_rule" "source_esp" {
  name        = "source-esp"
  region      = var.region
  ip_protocol = "ESP"
  ip_address  = google_compute_address.source_vpn_ip.address
  target      = google_compute_vpn_gateway.source_vpn_gateway.self_link
}

resource "google_compute_forwarding_rule" "source_udp500" {
  name        = "source-udp500"
  region      = var.region
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = google_compute_address.source_vpn_ip.address
  target      = google_compute_vpn_gateway.source_vpn_gateway.self_link
}

resource "google_compute_forwarding_rule" "source_udp4500" {
  name        = "source-udp4500"
  region      = var.region
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = google_compute_address.source_vpn_ip.address
  target      = google_compute_vpn_gateway.source_vpn_gateway.self_link
}

# ── Forwarding Rules — Target ─────────────────────────────────

resource "google_compute_forwarding_rule" "target_esp" {
  name        = "target-esp"
  region      = var.region
  ip_protocol = "ESP"
  ip_address  = google_compute_address.target_vpn_ip.address
  target      = google_compute_vpn_gateway.target_vpn_gateway.self_link
}

resource "google_compute_forwarding_rule" "target_udp500" {
  name        = "target-udp500"
  region      = var.region
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = google_compute_address.target_vpn_ip.address
  target      = google_compute_vpn_gateway.target_vpn_gateway.self_link
}

resource "google_compute_forwarding_rule" "target_udp4500" {
  name        = "target-udp4500"
  region      = var.region
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = google_compute_address.target_vpn_ip.address
  target      = google_compute_vpn_gateway.target_vpn_gateway.self_link
}

# ── Shared Secret ─────────────────────────────────────────────

resource "random_password" "vpn_secret" {
  length  = 32
  special = false
}

# ── VPN Tunnels ───────────────────────────────────────────────

resource "google_compute_vpn_tunnel" "source_to_target" {
  name               = "source-to-target"
  region             = var.region
  target_vpn_gateway = google_compute_vpn_gateway.source_vpn_gateway.self_link
  peer_ip            = google_compute_address.target_vpn_ip.address
  shared_secret      = random_password.vpn_secret.result


  local_traffic_selector  = ["10.0.1.0/24"]
  remote_traffic_selector = ["10.0.2.0/24"]

  depends_on = [
    google_compute_forwarding_rule.source_esp,
    google_compute_forwarding_rule.source_udp500,
    google_compute_forwarding_rule.source_udp4500
  ]
}

resource "google_compute_vpn_tunnel" "target_to_source" {
  name               = "target-to-source"
  region             = var.region
  target_vpn_gateway = google_compute_vpn_gateway.target_vpn_gateway.self_link
  peer_ip            = google_compute_address.source_vpn_ip.address
  shared_secret      = random_password.vpn_secret.result


  local_traffic_selector  = ["10.0.2.0/24"]
  remote_traffic_selector = ["10.0.1.0/24"]

  depends_on = [
    google_compute_forwarding_rule.target_esp,
    google_compute_forwarding_rule.target_udp500,
    google_compute_forwarding_rule.target_udp4500
  ]
}

# ── Static Routes ─────────────────────────────────────────────

resource "google_compute_route" "source_to_target_route" {
  name                = "source-to-target-route"
  network             = google_compute_network.source_vpc.name
  dest_range          = "10.0.2.0/24"
  priority            = 1000
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.source_to_target.self_link
}

resource "google_compute_route" "target_to_source_route" {
  name                = "target-to-source-route"
  network             = google_compute_network.target_vpc.name
  dest_range          = "10.0.1.0/24"
  priority            = 1000
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.target_to_source.self_link
}
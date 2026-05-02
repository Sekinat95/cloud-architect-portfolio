# ── HA VPN Gateways ───────────────────────────────────────────

resource "google_compute_ha_vpn_gateway" "source_vpn_gateway" {
  name    = "source-vpn-gateway"
  network = google_compute_network.source_vpc.id
  region  = var.region
}

resource "google_compute_ha_vpn_gateway" "target_vpn_gateway" {
  name    = "target-vpn-gateway"
  network = google_compute_network.target_vpc.id
  region  = var.region
}

# ── Cloud Routers ─────────────────────────────────────────────

resource "google_compute_router" "source_router" {
  name    = "source-router"
  network = google_compute_network.source_vpc.id
  region  = var.region

  bgp {
    asn               = 64512
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
  }
}

resource "google_compute_router" "target_router" {
  name    = "target-router"
  network = google_compute_network.target_vpc.id
  region  = var.region

  bgp {
    asn               = 64513
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
  }
}

# ── VPN Tunnels ───────────────────────────────────────────────
# HA VPN requires 2 tunnels per gateway pair (4 total)
# Tunnel 0 and 1 correspond to gateway interfaces 0 and 1

resource "google_compute_vpn_tunnel" "source_to_target_0" {
  name                  = "source-to-target-0"
  region                = var.region
  vpn_gateway           = google_compute_ha_vpn_gateway.source_vpn_gateway.self_link
  vpn_gateway_interface = 0
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.target_vpn_gateway.self_link
  router                = google_compute_router.source_router.self_link
  shared_secret         = "source-to-target-secret"
}

resource "google_compute_vpn_tunnel" "source_to_target_1" {
  name                  = "source-to-target-1"
  region                = var.region
  vpn_gateway           = google_compute_ha_vpn_gateway.source_vpn_gateway.self_link
  vpn_gateway_interface = 1
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.target_vpn_gateway.self_link
  router                = google_compute_router.source_router.self_link
  shared_secret         = "source-to-target-secret"
}

resource "google_compute_vpn_tunnel" "target_to_source_0" {
  name                  = "target-to-source-0"
  region                = var.region
  vpn_gateway           = google_compute_ha_vpn_gateway.target_vpn_gateway.self_link
  vpn_gateway_interface = 0
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.source_vpn_gateway.self_link
  router                = google_compute_router.target_router.self_link
  shared_secret         = "source-to-target-secret"
}

resource "google_compute_vpn_tunnel" "target_to_source_1" {
  name                  = "target-to-source-1"
  region                = var.region
  vpn_gateway           = google_compute_ha_vpn_gateway.target_vpn_gateway.self_link
  vpn_gateway_interface = 1
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.source_vpn_gateway.self_link
  router                = google_compute_router.target_router.self_link
  shared_secret         = "source-to-target-secret"
}

# ── Router Interfaces ─────────────────────────────────────────

resource "google_compute_router_interface" "source_interface_0" {
  name       = "source-interface-0"
  router     = google_compute_router.source_router.name
  region     = var.region
  vpn_tunnel = google_compute_vpn_tunnel.source_to_target_0.name
  ip_range   = "169.254.0.1/30"
}

resource "google_compute_router_interface" "source_interface_1" {
  name       = "source-interface-1"
  router     = google_compute_router.source_router.name
  region     = var.region
  vpn_tunnel = google_compute_vpn_tunnel.source_to_target_1.name
  ip_range   = "169.254.1.1/30"
}

resource "google_compute_router_interface" "target_interface_0" {
  name       = "target-interface-0"
  router     = google_compute_router.target_router.name
  region     = var.region
  vpn_tunnel = google_compute_vpn_tunnel.target_to_source_0.name
  ip_range   = "169.254.0.2/30"
}

resource "google_compute_router_interface" "target_interface_1" {
  name       = "target-interface-1"
  router     = google_compute_router.target_router.name
  region     = var.region
  vpn_tunnel = google_compute_vpn_tunnel.target_to_source_1.name
  ip_range   = "169.254.1.2/30"
}

# ── BGP Peers ─────────────────────────────────────────────────

resource "google_compute_router_peer" "source_peer_0" {
  name            = "source-peer-0"
  router          = google_compute_router.source_router.name
  region          = var.region
  peer_asn        = 64513
  peer_ip_address = "169.254.0.2"
  interface       = google_compute_router_interface.source_interface_0.name
}

resource "google_compute_router_peer" "source_peer_1" {
  name            = "source-peer-1"
  router          = google_compute_router.source_router.name
  region          = var.region
  peer_asn        = 64513
  peer_ip_address = "169.254.1.2"
  interface       = google_compute_router_interface.source_interface_1.name
}

resource "google_compute_router_peer" "target_peer_0" {
  name            = "target-peer-0"
  router          = google_compute_router.target_router.name
  region          = var.region
  peer_asn        = 64512
  peer_ip_address = "169.254.0.1"
  interface       = google_compute_router_interface.target_interface_0.name
}

resource "google_compute_router_peer" "target_peer_1" {
  name            = "target-peer-1"
  router          = google_compute_router.target_router.name
  region          = var.region
  peer_asn        = 64512
  peer_ip_address = "169.254.1.1"
  interface       = google_compute_router_interface.target_interface_1.name
}
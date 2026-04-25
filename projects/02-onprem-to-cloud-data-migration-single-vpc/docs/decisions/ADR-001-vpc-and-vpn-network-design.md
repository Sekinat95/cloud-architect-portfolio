# ADR-001: VPC and VPN Network Design

## Status
Accepted

## Date
2026-04-17

## Context
This project simulates an on-premises PostgreSQL database migration 
to Cloud SQL on GCP. A single VPC network is used for both the source and the destination 
databases. The goal for this project was to implement continuous migration 
through change data capture (CDC), as such simulating with a single VPC to avoid configuration complexities was used.

## Decision
We will deploy the source PostgreSQL VM and target Cloud SQL instance 
in separate VPCs, connected via a Cloud VPN Gateway with encrypted 
tunnels, simulating the network boundary between an on-premises 
environment and GCP.

## Alternatives Considered

| Option | Reason Rejected |
|--------|----------------|
| Single shared VPC | Does not simulate on-prem network boundary, no architectural realism |
| VPC Peering | Implies trusted internal relationship, not an external network boundary |
| Public internet connectivity | Insecure, not representative of enterprise migration patterns |

## Rationale
A VPN Gateway between two isolated VPCs accurately models the 
encrypted tunnel enterprises use when connecting on-premises 
infrastructure to GCP via Cloud VPN or Cloud Interconnect.

This design forces real architectural concerns:
- Routing configuration between VPCs
- Firewall rules governing cross-network traffic
- Encrypted transit for sensitive data in flight
- Private connectivity to Cloud SQL without public IP exposure

## Consequences

### Positive
- Network topology reflects real enterprise migration patterns
- Encrypted transit between source and target environments
- Firewall rules provide explicit, auditable access control
- Architecture is directly transferable to production scenarios

### Negative / Tradeoffs
- Adds provisioning complexity vs a single VPC approach
- VPN Gateway incurs additional cost during PoC execution
- VPN tunnel configuration in Terraform requires careful 
  routing table management

## Related Decisions
- ADR-003: Cloud SQL vs AlloyDB — target database placement 
  within the target VPC
- ADR-004: Terraform for IaC — VPC and VPN resources are 
  fully provisioned via Terraform

## References
- [Cloud VPN Overview](https://cloud.google.com/network-connectivity/docs/vpn/concepts/overview)
- [GCP VPC Documentation](https://cloud.google.com/vpc/docs/vpc)
- [Terraform google_compute_vpn_gateway](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_vpn_gateway)
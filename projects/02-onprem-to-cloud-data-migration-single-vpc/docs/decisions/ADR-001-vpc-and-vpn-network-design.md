# ADR-001: Single VPC vs 2-VPC Architecture

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
We will deploy the source PostgreSQL VM and target CloudSQL instance in the same vpc. 
As such they are able to connect with no additional configuartion as they are in the same network.
Database migration service (DMS) is used along with private service connect to move the data from the source to the target DB


## Alternatives Considered

| Option | Reason Rejected |
|--------|----------------|
| Separate VPCs for source and target DBs | Simulates more intuitively the separation between on-prem and cloud. Computationally complex |
| VPC Peering | Implies trusted internal relationship, not an external network boundary |
| Public internet connectivity | Insecure, not representative of enterprise migration patterns |

## Rationale
This architecture uses a single VPC for both the source and destination DBs (in separate subnets). The reason for this is simply that the goal of this project is to achieve replication and continuous migration easily with less computational complexity.

## Consequences

### Positive
- Minimal first version of a data migration task is acheived. 
- Firewall rules provide auditable access control


### Negative / Tradeoffs
- May be less realistically representative of real-world equivalent scenarios.


## Related Decisions
- ADR-003: Cloud SQL vs AlloyDB — target database placement 
  within the target VPC
- ADR-004: Terraform for IaC — VPC and VPN resources are 
  fully provisioned via Terraform

## References
- [GCP VPC Documentation](https://cloud.google.com/vpc/docs/vpc)
- [Terraform google_compute_vpn_gateway](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_vpn_gateway)
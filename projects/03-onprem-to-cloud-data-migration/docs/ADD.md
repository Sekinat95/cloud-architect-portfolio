# Overview
This version of the [DB migration from on-prem to cloud](../../02-onprem-to-cloud-data-migration-single-vpc/README.md) which uses 2 VPCs rather than one is detailed here.


# Architecture Diagrams
[Overview diagram](../diagrams/architecture-overview.mmd) of the 2 VPC design is available



# Architecture Decision Records

| ADR | Title | Status | Date |
|---|---|---|---|
| ADR-001 | [Single VPC vs Two-VPC](./decisions/ADR-001-vpc-and-vpn-network-design.md) | Accepted | 2026-05-02 |
| ADR-002 | [DMS vs Alternatives ](./decisions/ADR-002-DMS-vs-alternatives.md)| Accepted | 2026-05-02 |
| ADR-003 | [Cloud SQL vs AlloyDB ](./decisions/ADR-003-cloudsql-vs-alloydb.md)| Accepted | 2026-05-02 |
| ADR-004 | [pglogical for CDC ](./decisions/ADR-004-pglogical-for-CDC.md)| Accepted | 2026-05-02 |
| ADR-005 | [Terraform for IaC](./decisions/ADR-005-Terraform-for-IaC.md) | Accepted | 2026-05-02 |
| ADR-006 | [BGP vs Peering or private service connect](./decisions/ADR-006-BGP-HAVPN-vs-alternatives.md) | Accepted | 2026-05-02 |



# Results

## Reasons for failure


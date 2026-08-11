# On-Premises to Cloud Data Migration — Single VPC Architecture

## Project Overview

This project demonstrates a continuous database migration from a simulated on-premises PostgreSQL database to Google Cloud SQL PostgreSQL 15 using Google Cloud Database Migration Service (DMS) with Change Data Capture (CDC).

The architecture uses a single GCP VPC to simulate the network topology of a real
production migration where an on-premises database is connected to a single cloud
VPC via Dedicated Interconnect or Cloud VPN.

As will be further explained, this design choice is deliberate and was informed by the limitations of attempting such a simulation within the bounds of GCP's own policies.


# Architecture Diagrams
[Full Architectural Overview](../diagrams/architecture-overview.png)
[Network Topology](../diagrams/network-topology.png)
[Migration Flow](../diagrams/migration-flow.png)


# Architecture Decision Records

| ADR | Title | Status | Date |
|---|---|---|---|
| ADR-001 | [Single VPC vs Two-VPC](./decisions/ADR-001-vpc-and-vpn-network-design.md) | Accepted | 2026-04-23 |
| ADR-002 | [DMS vs Alternatives ](./decisions/ADR-002-DMS-vs-alternatives.md)| Accepted | 2026-04-23 |
| ADR-003 | [Cloud SQL vs AlloyDB ](./decisions/ADR-003-cloudsql-vs-alloydb.md)| Accepted | 2026-04-23 |
| ADR-004 | [pglogical for CDC ](./decisions/ADR-004-pglogical-for-CDC.md)| Accepted | 2026-04-23 |
| ADR-005 | [Terraform for IaC](./decisions/ADR-005-Terraform-for-IaC.md) | Accepted | 2026-04-23 |




# POC Video Demo Results
[Full Implementation Until CDC](https://www.loom.com/share/806b175b55764ebea9e51bb93447789c)
[CDC to promotion and cutoff + Validation](https://www.loom.com/share/7471ae18ceb14cc2b39a9b15b8da1092)

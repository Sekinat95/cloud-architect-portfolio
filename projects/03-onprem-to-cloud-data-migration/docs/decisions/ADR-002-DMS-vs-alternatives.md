# ADR-002: Database Migration Service vs Alternatives

## Status
Accepted

## Date
2026-04-17

## Context
A mechanism is required to migrate a PostgreSQL database from a 
simulated on-premises Compute Engine VM to a managed Cloud SQL 
instance. The migration approach must:
- Minimise downtime during cutover
- Maintain data integrity throughout the process
- Align with GCP-native tooling
- Be representative of production-grade migration patterns

## Decision
We will use GCP Database Migration Service (DMS) as the primary 
migration tool, configured with Change Data Capture (CDC) to enable 
continuous replication and minimal cutover downtime.

## Alternatives Considered

| Option | Reason Rejected |
|--------|----------------|
| pg_dump / pg_restore | Requires full downtime, no continuous replication, not production-grade |
| Custom Python ETL script | Reinvents the wheel, error-prone, no built-in monitoring or CDC |
| Cloud Data Fusion | Designed for complex ETL pipelines, overkill for lift-and-shift DB migration |
| Config Connector | Requires GKE cluster dependency, adds unnecessary complexity |

## Rationale
DMS is purpose-built for database migration and directly addresses 
the core requirements of this project:

**Minimal downtime via CDC:**
DMS uses PostgreSQL logical replication to continuously capture 
changes on the source database during migration. This means the 
source remains live throughout, with only seconds of downtime 
required at cutover when the target has fully caught up.

**GCP-native integration:**
DMS integrates natively with Cloud SQL, IAM service accounts, 
and Secret Manager for credentials — no custom integration 
work required.

**Built-in observability:**
DMS exposes migration metrics and logs to Cloud Monitoring 
out of the box, supporting the validation and monitoring 
stage of this project.

**Cost efficiency:**
DMS itself carries no additional service charge. The first 
50GB migrated via backfill method is free monthly. CDC costs 
are tiered with volume discounts, making it cost-effective 
at PoC scale.

## Consequences

### Positive
- Continuous replication via CDC minimises cutover downtime
- Native integration with Cloud SQL reduces configuration overhead
- Built-in monitoring feeds directly into validation stage
- Represents production-grade migration tooling recognisable 
  to hiring managers and clients

### Negative / Tradeoffs
- DMS requires PostgreSQL logical replication to be enabled 
  on the source — requires source VM configuration
- CDC adds complexity vs a simple dump/restore approach
- DMS Terraform resource requires careful configuration of 
  connection profiles before migration job creation

## Related Decisions
- ADR-001: VPC and VPN Network Design — DMS operates across 
  the VPN tunnel between source and target VPCs
- ADR-003: Cloud SQL vs AlloyDB — DMS target is Cloud SQL 
  PostgreSQL instance

## References
- [Database Migration Service Overview](https://cloud.google.com/database-migration/docs/overview)
- [DMS Pricing](https://cloud.google.com/database-migration/pricing)
- [PostgreSQL Logical Replication](https://www.postgresql.org/docs/current/logical-replication.html)
- [Terraform google_database_migration_service_migration_job](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/database_migration_service_migration_job)
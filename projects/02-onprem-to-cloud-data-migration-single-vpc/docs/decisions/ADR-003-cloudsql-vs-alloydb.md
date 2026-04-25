# ADR-003: Cloud SQL vs AlloyDB

## Status
Accepted

## Date
2026-04-17

## Context
A managed PostgreSQL target database must be selected on GCP to 
receive the migrated data from the on-premises source. The primary 
candidates are Cloud SQL for PostgreSQL and AlloyDB for PostgreSQL, 
both of which are fully managed and PostgreSQL-compatible.

The selection must prioritise migration fidelity, tooling 
compatibility, and simplicity over performance optimisation, 
as this is a lift-and-shift migration PoC rather than a 
platform modernisation exercise.

## Decision
We will use Cloud SQL for PostgreSQL as the migration target. 
Platform modernisation to AlloyDB is explicitly deferred as a 
separate architectural decision post-migration.

## Alternatives Considered

| Option | Reason Rejected |
|--------|----------------|
| AlloyDB for PostgreSQL | Introduces platform modernisation complexity into a lift-and-shift migration, DMS support is newer and less mature |
| BigQuery | Analytical warehouse, not appropriate for transactional workload migration |
| Bare PostgreSQL on Compute Engine | Loses managed service benefits, increases operational overhead |

## Rationale
The core principle driving this decision is:

> **Migration and modernisation are separate phases and should 
> not be conflated.**

Attempting to modernise the platform during migration introduces 
unnecessary risk — if issues arise it becomes unclear whether 
they stem from the migration process or the platform change.

Cloud SQL is the natural, well-trodden DMS target for PostgreSQL 
migrations with the most mature tooling support. It provides:
- Full PostgreSQL compatibility with minimal schema changes
- Native DMS integration as a first-class target
- Managed backups, HA, and read replicas out of the box
- A clear upgrade path to AlloyDB post-migration if required

AlloyDB remains a valid future consideration once the workload 
is stable in the cloud and performance requirements are better 
understood.

## Consequences

### Positive
- Simplest, most reliable DMS migration target for PostgreSQL
- Full feature parity with source PostgreSQL reduces 
  compatibility risk
- Clear post-migration modernisation path to AlloyDB available
- Well-documented, mature Terraform provider support

### Negative / Tradeoffs
- Foregoes AlloyDB performance benefits in the short term
- Requires a separate future project to evaluate AlloyDB 
  if performance demands it

## Related Decisions
- ADR-002: DMS vs Alternatives — Cloud SQL is the DMS 
  target database
- ADR-001: VPC and VPN Network Design — Cloud SQL instance 
  deployed with private IP within target VPC

## References
- [Cloud SQL for PostgreSQL](https://cloud.google.com/sql/docs/postgres)
- [AlloyDB Overview](https://cloud.google.com/alloydb/docs/overview)
- [DMS to Cloud SQL](https://cloud.google.com/database-migration/docs/postgres/quickstart)
- [Terraform google_sql_database_instance](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance)
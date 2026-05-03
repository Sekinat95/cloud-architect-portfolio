# ADR-004: PGLOGICAL FOR CDC Replication

## Status
Accepted

## Date
2026-04-23

## Context
GCP Database Migration Service requires a logical replication mechanism
on the source PostgreSQL instance to enable Change Data Capture (CDC).
CDC is the foundation of continuous migration — it streams ongoing
changes from the source to the destination, allowing the source to
remain live during migration and minimising cutover downtime.

PostgreSQL supports logical replication natively via its built-in
`pg_logical` infrastructure, but DMS specifically requires the
`pglogical` extension to be installed and configured on the source
database before CDC can be established.

This requirement was not prominently documented in DMS setup guides
and was discovered during the migration execution phase.

## Decision
We will install and configure the `pglogical` extension on the source
PostgreSQL instance as a prerequisite for DMS CDC replication. This
includes:

- Installing the `postgresql-13-pglogical` package
- Adding `pglogical` to `shared_preload_libraries` in `postgresql.conf`
- Creating the extension in all databases DMS will replicate
- Granting the migration user `USAGE` on the `pglogical` schema
- Granting the migration user `SELECT` on all `pglogical` tables

## Alternatives Considered

| Option | Reason Rejected |
|--------|----------------|
| PostgreSQL built-in logical replication only | DMS specifically requires the pglogical extension — built-in logical replication alone is insufficient |
| Datastream instead of DMS | Datastream is a separate GCP service designed for streaming analytics pipelines, not database migration — introduces unnecessary complexity for a lift-and-shift migration |
| pg_dump instead of CDC | Requires full source downtime during migration — rejected in ADR-002 |

## Rationale
`pglogical` is a PostgreSQL extension that implements logical replication
using a publish/subscribe model. It extends PostgreSQL's built-in
logical decoding capabilities to provide:

- **Replication sets** — fine-grained control over which tables are
  replicated
- **Conflict resolution** — handles write conflicts between source
  and target during replication
- **Cross-version replication** — supports replication between
  different PostgreSQL major versions

DMS uses `pglogical` internally to create replication slots on the
source database and subscribe to the WAL (Write Ahead Log) stream.
When DMS starts a CONTINUOUS migration job it:

1. Creates a pglogical node on the source
2. Creates a replication set containing all tables to be migrated
3. Creates a subscription on the Cloud SQL target
4. Performs the initial FULL_DUMP using the replication slot snapshot
5. Transitions to CDC mode, streaming all subsequent WAL changes

Without `pglogical` installed DMS cannot establish the replication
slot and the migration job fails with `NO_PGLOGICAL_INSTALLED`.

**Key operational discovery:**
The `migration_user` requires explicit privileges on the `pglogical`
schema and its tables — not just database-level privileges. The
following grants are required:

```sql
GRANT USAGE ON SCHEMA pglogical TO migration_user;
GRANT ALL ON ALL TABLES IN SCHEMA pglogical TO migration_user;
```

Failure to grant these results in `AUTHENTICATION_FAILURE` even when
the migration user has full database privileges.

## Consequences

### Positive
- Enables true CDC replication with minimal cutover downtime
- pglogical is a stable, mature PostgreSQL extension maintained by
  2ndQuadrant (now part of EDB)
- Replication sets provide granular control over what is migrated
- Cross-version replication support future-proofs the migration
  approach for PostgreSQL version upgrades

### Negative / Tradeoffs
- Adds a prerequisite installation step to the source VM provisioning
- `shared_preload_libraries` change requires a PostgreSQL restart —
  must be completed before any migration attempt
- pglogical privileges must be granted separately from standard
  database privileges — a non-obvious configuration requirement
- The extension must be created in every database DMS will replicate,
  including `postgres` (the default database DMS checks first)

## Related Decisions
- ADR-002: Database Migration Service vs Alternatives — DMS is the
  migration tool that requires pglogical as a prerequisite
- ADR-004: Terraform for IaC — pglogical installation is handled
  in `startup.sh` executed by the Compute Engine VM at boot

## References
- [pglogical GitHub](https://github.com/2ndQuadrant/pglogical)
- [DMS PostgreSQL Prerequisites](https://cloud.google.com/database-migration/docs/postgres/configure-source-database)
- [PostgreSQL Logical Decoding](https://www.postgresql.org/docs/13/logicaldecoding.html)
- [DMS Troubleshooting — NO_PGLOGICAL_INSTALLED](https://cloud.google.com/database-migration/docs/diagnose-issues)

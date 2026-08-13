# ADR-002: pgvector enablement method: post-provisioning no db-flag

## Status
Accepted

## Date
2026-04-17

## Context and decision
CloudSQL postgreSQL 15 pgvector is used and enabled by running  `CREATE EXTENSION` vector against the database after the instance exists. Attempting to use `cloudsql.enable_pgvector` database flag before the instance exists .
This choice is justified for cost/simplicity on a poc scale and to reuse relational infrastructure already in the portfolio.

## Alternatives Considered
The alternative is to use a database flag approach which attempts to enable a flag before the databaseinstance exists. This ultimately is the wrong approach as it flags an error becuase its incorrect for this cloudSQL postgresSQl 15 engine version.
Another alternative is to use a managed DB vector DB (eg Vertex AI vector search) but it was rejected for cost and simplicity that the chosen option provided.

<!-- ## Rationale
## Consequences
### Positive
### Negative / Tradeoffs
## Related Decisions
## References -->

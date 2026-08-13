# ADR-005: Embedding model choice


## Status
Accepted

## Date
2026-04-17

## Context and decision
The embedding model choice used was `text-embedding-004` via vertex AI. This was chosen over a third party embedding API for its native GCP integration.This choice keeps the whole pipleine in one cloud ecosystem (auth, billing, latency) simplifying IAM and networking vs calling an external API.

## Alternatives Considered
The alternatives are openAI/Cohere embedding APIs. They were rejected to avoid a second vendor's auth/billing/network dependcy in an otherwise all GCP architecture.

<!-- ## Rationale
## Consequences
### Positive
### Negative / Tradeoffs
## Related Decisions
## References -->

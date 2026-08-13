# ADR-001: CloudSQL pgvector vs managed vector database


## Status
Accepted

## Date
2026-04-17

## Context and decision
The pipeline needs a place to store embeddings and perform similarity search. CloudSQL postgreSQL pgvector is chosen for this. pgvector reuses relational infrastructure already familiar (from earlier PoCs) and it keeps cost low (no separate managed vector service)  and it is enough for PoC scale retreuval correctness demos.

## Alternatives Considered
The alternative is Vertex AI vector search (managed, purpose-built Approximate Nearest Neighbour (ANN) service). This was rejected for PoC scope and adds cost and complexity disproportionate to a demo needing only correctness not scale/latency at production ANN volumes
A self hosted vector DB (eg Qdrant/Weaviate on GCE) was rejected as unnecessary operational overhead for what cloud SQL already covers.

<!-- | Option | Reason Rejected |
|--------|----------------| -->

<!-- 
## Rationale
## Consequences
### Positive
### Negative / Tradeoffs
## Related Decisions
## References -->

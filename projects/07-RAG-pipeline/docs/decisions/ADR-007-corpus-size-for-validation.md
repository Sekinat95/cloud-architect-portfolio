# ADR-007: Corpus size for validation


## Status
Accepted

## Date
2026-04-17

## Context and decision
For our evaluation, we needed enough documents to demonstrate retreival and to discriminate between sources not just returning what was available. Two documents were utilised for this , justified by the fact that they have diffrent topics and 2 is the minimum sufficient number to prove multi-source retreival correctness. More importtantly this choice was made because the purpose of this poc is mechanicsm validation not scale testing.

## Alternatives Considered

<!-- | Option | Reason Rejected |
|--------|----------------| -->

The alternative is a larger corpus (10-100 documents) and it was rejected as unnecessary for proving the mechanism.

## Scope expansion in other iterations

For higher iterations of this poc, the focus will shift to retrival at scale, index performance under load, and chunking trade-offs  at volume. We will demonstrate sharding, Hierarchical Navigable Small World(HNSW) tuning, batch embedding etc when this is done


<!-- ## Consequences

### Positive



### Negative / Tradeoffs



## Related Decisions


## References -->

# ADR-004: Chunking strategy

## Status
Accepted

## Date
2026-04-17

## Context and decision
Documents need to be split before embedding and chunk size affects retreival precision and generation context quality. The chunking strategy used was `RecursiveCharacterTextSplitter` with a `chunk size 1000/overlap 150`(tradeoff between retreival granularity and context coherence). `RecursiveCharacterTextSplitter` respects natural text boundaries. `chunk size 1000/overlap 150` balances chunks large enough to retain coherent context against small enough to keep reterival precise and avoid diluting relevant content with irrelevant neighbouring text.
## Alternatives Considered
Smaller chunks (e.g., 300–500) would shrpen retreival precision but risk fragmenting context needed for coherent answers. Larger chunks (eg 2000+) would preserve more context per chunk but blur retreival precision and increase token cost per query. 
fixed size character/token splitting without overlap rejected as it risks spliting sentences/ideas at hard boundaries.

<!-- ## Rationale
## Consequences
### Positive
### Negative / Tradeoffs
## Related Decisions
## References -->

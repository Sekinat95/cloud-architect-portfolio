# ADR-008: Reterival quality signal
 <!-- Retrieval quality signal: heuristic vs. formal eval — structured logging with an insufficient_context heuristic (phrase-matching on refusal language) as an interim retrieval-quality proxy, with RAGAS evaluation planned as the follow-up, more rigorous measure — good ADR on "why heuristic now, formal eval later.". -->

## Status
Accepted

## Date
2026-04-17

## Context and decision
The pipeline needs some signal for whether retrival/generation quality is good without building a full eval framework immediately. It gives a cheap immediate proxy signal for retreival failures. This is sequenced before the more rigorous RAGAS evaluation. It uses an insufficient_context structured-logging event triggered by the LLM's refusal-language phrase matching. 

## Alternatives Considered



The alternative is to jump straight to RAGAS. This was however rejected becuase not doing so means doing evaluation before core pipeline correctness(multi-sorce retreival, grounded refusal) is confirmed end to end.
Trigering on zero-document-retreival is an everlier version of this heuristic and it was replaced because it misses cases where documents were retrieved but were the wrong ones. Phrase-matching on the LLM's own refusal langauge catches it.

<!-- ## Rationale


## Consequences

### Positive



### Negative / Tradeoffs -->



## Related Decisions


## References

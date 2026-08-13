# ADR-009: Groundedness or refusal behaviour during generation

## Status
Accepted

## Date
2026-04-17

## Context and Decision
 Explicit refusal on insufficient context was designed and verified at the generation stage in testing. When retreived context does not contain the anwser, the LLM could either hallucinate 
 a plausible-sounding anwser or explicitly decline. This is important in security contexts as an hallucinated answer is worse than no answer.


<!-- ## Decision -->

## Alternatives Considered


Alternativley a best-effort generation regardless of context sufficiency could have been used. 
This uses a hard coded refusal threshold based purely on retreival similarity score cutoff and not what was implemented. This typicaally produces risks of confident hallucination.
The chosen approach lets the LLM's own answer signal insufficiency and is better than using similarity scores.

<!-- ## Rationale

## Consequences

### Positive -->



### Negative / Tradeoffs



## Related Decisions


## References

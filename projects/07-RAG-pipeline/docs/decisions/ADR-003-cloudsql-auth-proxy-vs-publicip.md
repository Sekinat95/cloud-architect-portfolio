# ADR-003: CloudSQL Auth Proxy vs Public IP

## Status
Accepted

## Date
2026-04-17

## Context and decision
The pipeline (which runs in cloud shell/eventually a compute context) needs to connect to cloudSQL. Auth Proxy on 127.0.0.1:5432 uses IAM-based authorized connections and encrypts traffic without exposing the instance to the public internet. 


## Alternatives Considered
The alternative is to use public IP with authorised networks. This was rejected as a larger attack surface and manula IP allowlist maintenance. Private IP/VPC peering direct connection is another reasonbale alternative not chosen because of setup simplicity in a poc context. This would be a viable consideration in production (a hardening step).

<!-- ## Rationale
## Consequences
### Positive
### Negative / Tradeoffs
## Related Decisions
## References -->

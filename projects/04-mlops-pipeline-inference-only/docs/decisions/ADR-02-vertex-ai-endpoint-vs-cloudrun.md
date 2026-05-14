# ADR-002: Vertex AI endpoint vs Cloudrun

## status
Accepted

## Date
2026-05-07

## Context and Decision
The online endpoint was provisioned with vertex AI endpoints. The purpose of the online endpoint is to enable single unit infrence requests. This functionality was implemented by manually sending a request through cloud shell.

Cloud Shell
    → python `test_endpoint.py`
    → deploys endpoint
    → sends 5 test sentences
    → prints predictions
    → deletes endpoint


## Alternatives Considered
This end of the pipeline **can also be automated using a smoke test script with gradual rollout**. For this PoC, this was sufficient.

## References
[Vertex AI Endpoint](https://docs.cloud.google.com/vertex-ai/docs/general/deployment)
[Agent Platform](https://docs.cloud.google.com/gemini-enterprise-agent-platform)
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
The online inference is triggered through a separate running on the `test_endpoint.py` script which creates the Vertex AI endpoint, runs the single inference and tears down the endpoint immediately. This is the design used for cost concsciousness in this PoC.
An alternative will be to incorpoate this step into the pipeline along with the other pipeline steps. A persistent online endpoint will need to be provisioned and once the pipeline succeeds upto batch infrence execution, the model is deployed to the persistent endpoint. A smoke test is conducted to check basic working success of the deployed model which determines if the endpoint is kept live or teared down (basiclaly if its not working , tear down, if not keep up). 
In CI/CD, this persistent endpoint solution can be added to the pipeline to be triggered along with the rest of the pipeline by cloudbuild and deployed by cloud deploy.

## References
[Vertex AI Endpoint](https://docs.cloud.google.com/vertex-ai/docs/general/deployment)
[Agent Platform](https://docs.cloud.google.com/gemini-enterprise-agent-platform)
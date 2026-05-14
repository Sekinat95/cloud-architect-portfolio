# ADR-001: Vertex AI pipelines orchestration

## status
Accepted

## Date
2026-05-07

## Context
This is an MLOPs pipeline implemented to process inference requests to a pre-trained model targeting financial sector sentiment analysis. It uses the pretrained FinBert model and the financial phrasebank dataset for conducting the inference tests. There are two configured inference formats: batch inference and single endpoint inference. 
At the tail end of the pipeline two modes of inferece trigger was confgured: manual trigger and CI/CD.

## Decision
The pipeline was built using GCP managed services entirely. We utilised vertex AI pipelines to set up all the required components from data and model storage to GCS and model registry as well as batch inference results in BigQuery and eventually the provisioning of the online endpoint, were all integrated seamlessly with Vertex AI pipelines.
For this PoC, Vertex AI pipelines used Kubeflow pipelines for orchestration

## Alternatives Considered

## Rationale

## Consequences

### Positives
- Seamless integration with other GCP services

### Negatives

## Related Decisions

## References
[Vertex AI pipelines](https://docs.cloud.google.com/vertex-ai/docs/pipelines/introduction?authuser=0)
[Vertex AI Agent Platform](https://docs.cloud.google.com/gemini-enterprise-agent-platform?authuser=0)
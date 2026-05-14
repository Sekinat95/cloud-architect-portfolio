# ADR-003: Vertex AI Model Registry

## status
Accepted

## Date
2026-05-07

## Context and Decision
The pretrained model was uploaded from hugging face. In order to decouple this workflow from external dependencies, we uploaded the model and stored pointers to it in Vertex AI model registry. This way the model can be used without constantly using the hugging face APIs.

## Alternatives Considered

## Reference
[Vertex AI model registry](https://docs.cloud.google.com/vertex-ai/docs/model-registry/introduction)


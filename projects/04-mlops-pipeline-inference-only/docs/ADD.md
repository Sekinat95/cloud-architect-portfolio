# MLOps INFERENCE PIPELINE 
## Overview
An Inference pipeline of a NLP sentiments analysis done on financial data. The workflow uses the following:
- FinBert pretrained model 
- Inference is conducted on financial phrasebank dataset
- The pipeline components consist of managed GCP services and tools.

There are two stages of this inference pipeline implementation. 
- The first one invloves the manual triggering of the pipeline by making an inference request throuhg a python script. - The second involves the addition of CI/CD into the pipeline to trigger inference calls on the online endpoint.

The following are the architectural decisions that were made:

# Architectural Decision Records
# Architecture Decision Records

| ADR | Title | Status | Date |
|---|---|---|---|
| ADR-001 | [Vertex AI pipelines Orchestration](./decisions/ADR-01-vertex-ai-pipelines-orchestration.md) | Accepted | 2026-05-07 |
| ADR-002 | [Vertex AI endpoints vs Cloudrun](./decisions/ADR-02-vertex-ai-endpoint-vs-cloudrun.md)| Accepted | 2026-05-07 |
| ADR-003 | [Vertex AI model registry](./decisions/ADR-03-model-registry.md)| Accepted | 2026-05-07 |
| ADR-004 | [CI/CD vs Manual Triggering](./decisions/ADR-04-ci-cd-vs-manual-triggering.md)| Accepted | 2026-05-07 |



# PoC Video Demo Results
[BATCH Inference Pipeline Online Endpoint with Manual Triggering](https://www.loom.com/share/e1ba711e3f794076ac635e44f59c9572) 

[Single Online Inference Endpoint Provisioned. Model still provisioning](https://www.loom.com/share/fa5805399115437da50e54c56b47f619)

[Manually Triggered Single Online Endpoint Successfully deployed](https://www.loom.com/share/6375f8490e8b4ee0b1a5c7d73ff82adc)

[CI/CD Introduced to trigger single online endpoint](https://www.loom.com/share/c50b853746204e7c9c1138ac1ba57d8e)

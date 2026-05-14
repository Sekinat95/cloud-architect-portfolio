# ADR-004: CI/CD

## status
accepted

## Date
2026-05-07


## Context and Decision
In the first part we created the pipeline provisioning manually by running each command in IaC with Terraform and cloud shell step by step and eventaually submitting the pipeline run, running batch inference and writing the result to BigQuery and registering the model on model regostry. 
In this step we automate all of these steps in a single workflow as follows triggered by a push to the github repositiry.


git push
    → Cloud Build fires
    → compiles pipeline.yaml
    → uploads to GCS
    → submits Vertex AI Pipeline run
    → pipeline runs batch inference on 2264 sentences
    → writes to BigQuery
    → registers model in Model Registry
    → Cloud Build exits


## References
[MLOps CI/CD Vertex AI Pipelines](https://docs.cloud.google.com/architecture/architecture-for-mlops-using-tfx-kubeflow-pipelines-and-cloud-build)
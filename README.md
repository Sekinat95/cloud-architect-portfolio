# MLOps, Cloud Architecture & Integration Portfolio
This repository contains artefacts (including architecture decision documents, diagrams, walkthroughs and demos) of independent projects carried out under cloud systems architecture. A lot of the projects are rooted in Machine Learning Engineering and Operations. They span end-to-end MLOps pipelines, cloud native infrastructure design and system integration. They are grounded in production gractices including infrastructure as code (IaC), automation (CI/CD), formal architectural documentation and third-party API integrations.
Each project is contained in a distinct folder which follows the following structure:

## Repository Structure

Each project under `/projects` is a self-contained, independently deployable PoC and follows a consistent layout:

```
/projects/NN-project-name
├── README.md                    # Project overview, architecture, results
├── WALKTHROUGH.md                # Step-by-step build reference
├── /docs
│   ├── ADD.md                    # Architecture Decision Document (TOGAF-aligned)
│   └── /decisions
│       ├── ADR-001-*.md          # One ADR per significant decision
│       └── ADR-00N-*.md
├── /terraform                    # All infrastructure as code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── *.tf                      # Service-specific configs (networking, iam, etc.)
├── /src  (or /pipeline)          # Application / pipeline code
└── /diagrams                     # Architecture and flow diagrams (PNG)
```

**Conventions across projects:**
- One GCP project per PoC — clean billing isolation, 
<!-- `terraform destroy` for full teardown -->
- `README.md` is the entry point; `WALKTHROUGH.md` is the reproducible build log
- Every non-trivial decision is documented in an architecture decision record (ADR)
- `.env` files are gitignored and created manually, never committed
- Project Flow Diagrams included
 <!-- **finish the rest of the diagrams please -->



# OVERVIEW OF EACH PROJECT:

- **PROJECT1 -> DB Migration with CDC - Single VPC**
    - *Project Folder*: [02-onprem-to-cloud-data-migration-single-vpc](./projects/02-onprem-to-cloud-data-migration-single-vpc/) 
    - *Short Description*: Single VPC contains both source and destination databases in a simulation of continuous DB migration using database migration service (DMS) and change data capture (CDC)
    - *README*: [Single VPC DB Migrattion README](./projects/02-onprem-to-cloud-data-migration-single-vpc/README.md)
    - *Diagram*: [Full Architectural Overview](./projects/02-onprem-to-cloud-data-migration-single-vpc/diagrams/architecture-overview.mmd) 
   

- **PROJECT1_2 -> DB Migration with CDC - Two VPCs**
    - *Project Folder*: [03-onprem-to-cloud-data-migration](./projects/03-onprem-to-cloud-data-migration/)
    - *Short Description*: Using two VPCs, simulating an on-prem to cloud DB migration and demonstrating why it fails in GCP.
    - *README*: [Two VPCs DB Migration README](./projects/03-onprem-to-cloud-data-migration/README.md)
    - *Diagram*: [Full Architecture Overview](./projects/03-onprem-to-cloud-data-migration/diagrams/architecture-overview.mmd)
    <!-- - *Demo of Implementation* -->

- **PROJECT2 -> MLOps Inference Pipeline**
    - *Project Folder*: [04-mlops-pipeline-inference-only](./projects/04-mlops-pipeline-inference-only/)
    - *Short Description*: End-to-end inference pipeline of financial sentiments analysis using FinBERT (a domain specific transformer model finetuned on financial text) covering ingestion, preprocessing, model serving and prediction output. 
    - *README*: [INFERENCE PIPELINE README](./projects/04-mlops-pipeline-inference-only/README.md)
    - *Diagram*: [Full Architectural Overview](./projects/03-onprem-to-cloud-data-migration/diagrams/architecture-overview.mmd)
    <!-- - *Demo of Implementation*: -->


- **PROJECT3 -> MLOps Inference Pipeline with TTS Integration (ElevenTTS)**
    - *Project Folder*: [05-inference-pipeline-w-eleventts](./projects/05-inference-pipeline-w-eleventts/)
    - *Short Description*: End-to-end inference pipeline of financial sentiments analysis using finBERT(the popular final model trained on top of BERT) and with text to speech integration using elevenLabs TTS API.
    - *README*: [ELEVENTTS INTEGRATION README](./projects/05-inference-pipeline-w-eleventts/README.md)
    - *Diagram*: [Full Architectural Overview](./projects/04-mlops-pipeline-inference-only/diagrams/architecture-overview.mmd)

- **PROJECT4 -> END-TO-END Forecasting Pipeline (Data Ingestion - Model Monitoring) => PhD Replication**
    - *Project Folder*: [06-phd-to-gcp-xr-ml-drx](./projects/06-phd-to-gcp-xr-ml-drx/)
    - *Short Description*: From data ingestion to model monitoring; Implementing the full cloud MLE workflow using my PhD project which improved energy efficiency in cellular networks UEs using Long Short Term Memory (LSTM) and Gaussian Process Regression (GPR) algorithms.
    - *README*: [Full Pipeline README](./projects/06-phd-to-gcp-xr-ml-drx/README.md)
    - *Diagram*: [Full Architectural Overview](./projects/06-phd-to-gcp-xr-ml-drx/diagrams/architecture-overview.mmd)


- **PROJECT5 -> Retreival Augmented Generation (RAG) Pipeline**
    - *Project Folder*: [07-RAG-pipeline](./projects/07-RAG-pipeline/)
    - *Short Description*: A basic RAG pipeline to query a pool of job application cover letters.
    - *README*: [RAG README](./projects/07-RAG-pipeline/README.md)
    - *Diagram*: [Full Architectural Overview](./projects/07-RAG-pipeline/diagrams/architecture-overview.mmd)





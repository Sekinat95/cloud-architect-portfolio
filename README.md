# CLOUD SYSTEM MLOPs & ARCHITECTURE  PORTFOLIO
This repository contains artefacts of independent projects carried out under machine learning engineering (MLE) and operations (MLOps) as well as cloud systems architecture (as much as possible). All projects except one are Cloud ML projects but all projects have followed the format of cloud architecture definition document (ADD). 

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
- One GCP project per PoC — clean billing isolation, `terraform destroy` for full teardown
- `README.md` is the entry point; `WALKTHROUGH.md` is the reproducible build log
- Every non-trivial decision is documented in an architecture decision record (ADR)
- `.env` files are gitignored and created manually, never committed
- Project Flow Diagrams are exported as PNG and referenced from
 the README, not embedded elsewhere



# OVERVIEW OF EACH PROJECT:

- **PROJECT1 -> DB Migration with CDC**
    - *Project Folder*: [02-onprem-to-cloud-data-migration-single-vpc](./projects/02-onprem-to-cloud-data-migration-single-vpc/) 
    - *Short Description*: Single VPC contains both source and destination databases in a simulation of continuous DB migration using database migration service (DMS) and change data capture (CDC)
    - *README*: [Single VPC DB Migrattion README](./projects/02-onprem-to-cloud-data-migration-single-vpc/README.md)
    - *Diagram*: [Full Architectural Overview](../diagrams/architecture-overview.png) 
   

- **PROJECT1_2 -> DB Migration with CDC**
    - *Project Folder*: [03-onprem-to-cloud-data-migration](./projects/03-onprem-to-cloud-data-migration/)
    - *Short Description*: Using two VPCs, simulating an on-prem to cloud DB migration and demonstrating why it fails in GCP.
    - *README*: [Two VPCs DB Migration README](./projects/03-onprem-to-cloud-data-migration/README.md)
    - *Diagram*: [Full Architecture Overview]()
    <!-- - *Demo of Implementation* -->

- **PROJECT2 -> MLOps Inference Pipeline**
    - *Project Folder*: [04-mlops-pipeline-inference-only](./projects/04-mlops-pipeline-inference-only/)
    - *Short Description*: Inference pipeline of financial sentiments analysis using finBERT(the popular final model trained on top of BERT). 
    - *README*: [INFERENCE PIPELINE README](./projects/04-mlops-pipeline-inference-only/README.md)
    - *Diagram*: [Full Architectural Overview]()
    <!-- - *Demo of Implementation*: -->


- **PROJECT3 -> MLOps Inference Pipeline with TTS Integration (ElevenTTS)**
    - *Project Folder*: [05-inference-pipeline-w-eleventts](./projects/05-inference-pipeline-w-eleventts/)
    - *Short Description*: Inference pipeline of financial sentiments analysis using finBERT(the popular final model trained on top of BERT) and with text to speech integration using elevenLabs TTS API.
    - *README*: [ELEVENTTS INTEGRATION README](./projects/05-inference-pipeline-w-eleventts/README.md)
    - *Diagram*: [Full Architectural Overview]()

- **PROJECT4 -> END-TO-END Forecasting Pipeline (Data Ingestion - Model Monitoring) => PhD Replication**
    - *Project Folder*: [06-phd-to-gcp-xr-ml-drx](./projects/06-phd-to-gcp-xr-ml-drx/)
    - *Short Description*: From data ingestion to model monitoring; Implementing the full cloud MLE workflow using my PhD project which improved energy efficiency in cellular networks UEs using Long Short Term Memory (LSTM) and Gaussian Process Regression (GPR) algorithms.
    - *README*: [Full Pipeline README](./projects/06-phd-to-gcp-xr-ml-drx/README.md)
    - *Diagram*: [Full Architectural Overview]()


- **PROJECT5 -> Retreival Augmented Generation (RAG) Pipeline**
    - *Project Folder*: [07-RAG-pipeline](./projects/07-RAG-pipeline/)
    - *Short Description*: A basic RAG pipeline to query a pool of job application cover letters.
    - *README*: [RAG README](./projects/07-RAG-pipeline/README.md)
    - *Diagram*: [Full Architectural Overview]()





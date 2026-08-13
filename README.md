# MLOps, Cloud Architecture & Integration Portfolio
## Portfolio Thesis
In this repository, I show through hands-on implementation and documentation, my understanding and experience and curiousity around cloud systems particularly machine learning operations (MLOps), integration engineering and architecture etc. 
My background combines expertise in Distributed Systems and Applied Machine Learning as well as Telecommunications Engineering. I also have experience working on production API design, engineering and integrations. 
This repository contains projects that showcase my knowledge of cloud systems architecture, MLOps, and Integration engineering. It contains the architecture design documents (ADDs) as well as the architecture decision record (ADRs), architecture diagrams and implementation artifacts including replication walkthroughs of each project. These projects are grounded in production practices including Infrastructure as code (IaC), automation (CI/CD), formal architectural documentation and third party API integrations. 

*This portfolio is a living document, continuously evolving as projects are iterated upon and new ones are added.*


## Repository Structure
Each project is contained in a distinct folder which follows the following structure:

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
Each project under `/projects` is a self-contained, independently deployable PoC and follows a consistent layout


## List of Projects:

- **PROJECT1 -> DB Migration with CDC - Single VPC**
    - *Project Folder*: [02-onprem-to-cloud-data-migration-single-vpc](./projects/02-onprem-to-cloud-data-migration-single-vpc/) 
    - *Short Description*: Simulated database migration from on-prem to cloud entirely on GCP.Using a single virtual private cloud(VPC). Achieved continuous replication through postgreSQL pglogical change data capture(CDC)
    - *README*: [Single VPC DB Migrattion README](./projects/02-onprem-to-cloud-data-migration-single-vpc/README.md)
    - *Diagram*: [Full Architectural Overview](./projects/02-onprem-to-cloud-data-migration-single-vpc/diagrams/architecture-overview.mmd) 
   

<!-- - **PROJECT1_2 -> DB Migration with CDC - Two VPCs**
    - *Project Folder*: [03-onprem-to-cloud-data-migration](./projects/03-onprem-to-cloud-data-migration/)
    - *Short Description*: Replicating the Single VPC DB migration simulation architecture with a 2-VPC design. Documenting the failures.
    - *README*: [Two VPCs DB Migration README](./projects/03-onprem-to-cloud-data-migration/README.md)
    - *Diagram*: [Full Architecture Overview](./projects/03-onprem-to-cloud-data-migration/diagrams/architecture-overview.mmd)
    - *Demo of Implementation* -->

- **PROJECT2 -> MLOps Inference Pipeline**
    - *Project Folder*: [04-mlops-pipeline-inference-only](./projects/04-mlops-pipeline-inference-only/)
    - *Short Description*: End-to-end inference pipeline of financial sentiments analysis using FinBERT (a domain specific transformer model finetuned on financial text) covering ingestion, preprocessing, model serving and prediction output. In a second iteration, integrating a text to speech API on the inference request functionality.
    - *README*: [INFERENCE PIPELINE README](./projects/04-mlops-pipeline-inference-only/README.md)
    - *Diagram*: [Full Architectural Overview](./projects/03-onprem-to-cloud-data-migration/diagrams/architecture-overview.mmd)
    <!-- - *Demo of Implementation*: -->


<!-- - **PROJECT3 -> MLOps Inference Pipeline with TTS Integration (ElevenTTS)**
    - *Project Folder*: [05-inference-pipeline-w-eleventts](./projects/05-inference-pipeline-w-eleventts/)
    - *Short Description*: End-to-end inference pipeline of financial sentiments analysis using finBERT and with text to speech integration using elevenLabs TTS API.
    - *README*: [ELEVENTTS INTEGRATION README](./projects/05-inference-pipeline-w-eleventts/README.md)
    - *Diagram*: [Full Architectural Overview](./projects/04-mlops-pipeline-inference-only/diagrams/architecture-overview.mmd) -->

- **PROJECT4 -> END-TO-END Forecasting Pipeline (Data Ingestion - Model Monitoring) => PhD Replication**
    - *Project Folder*: [06-phd-to-gcp-xr-ml-drx](./projects/06-phd-to-gcp-xr-ml-drx/)
    - *Short Description*: From data ingestion to model monitoring; Implementing the full cloud MLE workflow using my PhD project which improved energy efficiency in cellular networks UEs using Long Short Term Memory (LSTM) and Gaussian Process Regression (GPR) algorithms.
    - *README*: [Full Pipeline README](./projects/06-phd-to-gcp-xr-ml-drx/README.md)
    - *Diagram*: [Full Architectural Overview](./projects/06-phd-to-gcp-xr-ml-drx/diagrams/architecture-overview.mmd)


- **PROJECT5 -> Retreival Augmented Generation (RAG) Pipeline**
    - *Project Folder*: [07-RAG-pipeline](./projects/07-RAG-pipeline/)
    - *Short Description*: End-to-end RAG pipeline on GCP for document Q&A. LangChain, Vertex AI embeddings/generation, pgvector on cloudSQL as well as IaC through terraform. Multi-resource reteival and grounded refusal on insufficient context
    - *README*: [RAG README](./projects/07-RAG-pipeline/README.md)
    - *Diagram*: [Full Architectural Overview](./projects/07-RAG-pipeline/diagrams/architecture-overview.mmd)



<!-- **Conventions across projects:**
- One GCP project per PoC — clean billing isolation, 
<!-- `terraform destroy` for full teardown -->
<!-- - `README.md` is the entry point; `WALKTHROUGH.md` is the reproducible build log
- Every non-trivial decision is documented in an architecture decision record (ADR)
- `.env` files are gitignored and created manually, never committed
- Project Flow Diagrams included -->
 <!-- **finish the rest of the diagrams please --> 


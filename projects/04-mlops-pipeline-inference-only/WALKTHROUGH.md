# WALKTHROUGH

# MLOps Inference Pipeline — Build Walkthrough

Single end-to-end reference. Follow steps in order.

---

## Phase 0 — Setup

### Step 1 — Environment Variables

export PROJECT_ID=mlops-pipeline-inference-only
export REGION=europe-west2
export ZONE=europe-west2-a
export BUCKET_NAME=$PROJECT_ID-terraform-state
# persist to ~/.bashrc, source it

### Step 2 — Authenticate

gcloud auth application-default login
gcloud config set project $PROJECT_ID

### Step 3 — Terraform State Bucket

gsutil mb -p $PROJECT_ID -l $REGION gs://$BUCKET_NAME
gsutil versioning set on gs://$BUCKET_NAME

### Step 4 — Project Folder Structure

mkdir -p projects/04-mlops-pipeline-inference-only/{terraform,pipeline/components,inference,docs/decisions,diagrams}
# touch main.tf, variables.tf, outputs.tf, storage.tf, iam.tf, bigquery.tf
# touch pipeline/components/{data_validation,preprocessing,batch_inference,output_writer,model_upload}.py
# touch pipeline/{pipeline,run_pipeline}.py, inference/test_endpoint.py, cloudbuild.yaml

---

## Phase 1 — Terraform: Infrastructure

### Step 5 — main.tf
- Provider + GCS backend (bucket name hardcoded — backend initialises before variables)
- 9 API enablements: aiplatform, bigquery, bigquerystorage, cloudbuild,
  cloudscheduler, compute, iam, cloudresourcemanager, secretmanager, storage
- `time_sleep` 120s after API enablement — propagation delay

### Step 6 — variables.tf
project_id, region, zone, project_number

### Step 7 — storage.tf
Three GCS buckets: raw-data, model-artefacts, pipeline-root
(`force_destroy = true` on all — required for clean `terraform destroy`)

### Step 8 — iam.tf
- Service account: `mlops-pipeline-sa`
- Roles: aiplatform.user, storage.admin (not just Object Admin — Vertex AI
  Pipelines checks pipeline-root bucket existence), bigquery.dataEditor
- Self-impersonation: `roles/iam.serviceAccountUser` on itself — required for
  `job.submit(service_account=...)` when submitting SA == execution SA
- Cloud Build SA also needs `roles/logging.logWriter`

### Step 9 — bigquery.tf
Dataset `mlops_predictions`, table `finbert_predictions`
(schema includes run_id, run_timestamp, text, predicted_label, confidence, ground_truth)

### Step 10 — terraform apply
Verify: 3 buckets, 1 dataset+table, 1 service account, all provisioned

---

## Phase 2 — Data

### Step 11 — Upload Financial PhraseBank

pip install datasets google-cloud-storage pandas requests --break-system-packages
python pipeline/components/upload_data.py
# downloads sentences_allagree subset (2,264 sentences) from HuggingFace
# → raw-data bucket

---

## Phase 3 — Pipeline (Manual Stage)

This is the first of two execution stages: run the pipeline directly,
without CI/CD, to prove the components work end to end before automating.

### Step 12 — Install pipeline dependencies

pip install kfp google-cloud-aiplatform --break-system-packages

### Step 13 — Compile and submit

cd pipeline
python pipeline.py       # compiles KFP v2 DAG → pipeline.yaml
python run_pipeline.py   # submits compiled pipeline.yaml to Vertex AI Pipelines

Pipeline DAG:
1. Data Validation
2. Preprocessing (BertTokenizer)
3. Batch Inference (FinBERT, batches of 32) — label mapping {0: positive, 1: negative, 2: neutral}
4. Output Writer → BigQuery (write timestamp as pd.to_datetime(..., utc=True), not string)
5. Model Upload → Vertex AI Model Registry (HF_MODEL_ID=ProsusAI/finbert, HF_TASK=text-classification,
   HuggingFace PyTorch DLC container — generic PyTorch container expects a .mar file and will fail)

Monitor: console.cloud.google.com/vertex-ai/pipelines

### Step 14 — Batch inference evaluation

Query BigQuery for accuracy:

SELECT COUNTIF(correct) / COUNT(*) AS accuracy, predicted_label, COUNT(*)
FROM `mlops_predictions.finbert_predictions`
GROUP BY predicted_label

Achieved: 97.17% accuracy on sentences_allagree subset.

---

## Phase 4 — Online Endpoint (Post-Pipeline)

### Step 15 — Deploy to endpoint

Deploy registered model from Model Registry → Vertex AI Endpoint
(n1-standard-4, 1 replica, ~10 min deploy time)

### Step 16 — Live inference test

cd ../inference
python test_endpoint.py
# sends 5 financial sentences, request format {"text": "<sentence>"} — NOT {"inputs": ...}
# prints label + confidence per sentence

### Step 17 — Record demo, then tear down endpoint

endpoint.undeploy_all()
endpoint.delete()
# torn down immediately after demo — NFR: minimise cost, don't leave a live endpoint running

---

## Phase 5 — CI/CD (Automation Stage)

This is the second execution stage: wrap the manual pipeline run in
automated triggers, so future runs don't require the manual steps above.

### Step 18 — Cloud Build trigger (manual console step)

The GitHub repo connection requires a regional GitHub App mapping —
cannot be created via Terraform. One-time manual step at:
console.cloud.google.com/cloud-build/triggers

Trigger config: fires on push to `main`, scoped to
`projects/04-mlops-pipeline-inference-only/**`

cloudbuild.yaml steps:
1. Install KFP SDK, compile pipeline.py → pipeline.yaml (single bash -c step —
   pip installs don't persist between Cloud Build steps)
2. Copy pipeline.yaml to gs://.../compiled/
3. Install aiplatform SDK, submit pipeline run (async — build succeeds on
   submission, not completion; monitor actual run in Vertex AI console)

### Step 19 — Cloud Scheduler (weekly CT)

Provisioned in Terraform (cicd.tf). Schedule: `0 8 * * 1` (Mon 08:00 UTC).
Mechanism: HTTP POST to Vertex AI Pipelines API using the compiled
pipeline.yaml in GCS, authenticated via mlops-pipeline-sa OAuth token.

---

## Teardown

cd terraform
terraform destroy
gcloud storage rm -r gs://$PROJECT_ID-terraform-state

Note: delete the endpoint before `terraform destroy`, or it'll orphan.
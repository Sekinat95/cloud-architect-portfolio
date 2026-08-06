# RAG Pipeline — Build Walkthrough

End-to-end retrieval-augmented generation pipeline on GCP. Ingests PDFs,
chunks, embeds into pgvector, retrieves, and generates grounded answers
with source citations via Gemini.

---

## Phase 0 — Setup

### Step 1 — Environment Variables

export PROJECT_ID=rag-pipeline-501417
export REGION=europe-west2
export ZONE=europe-west2-a
export BUCKET_NAME=$PROJECT_ID-state

### Step 2 — Authenticate

gcloud auth application-default login
gcloud config set project $PROJECT_ID
gcloud services enable cloudresourcemanager.googleapis.com   # manual pre-enable — Terraform can't enable other APIs without this first

### Step 3 — Terraform State Bucket

gsutil mb -p $PROJECT_ID -l $REGION gs://$BUCKET_NAME
gsutil versioning set on gs://$BUCKET_NAME

### Step 4 — Project Folder Structure

mkdir -p projects/07-RAG-pipeline/{terraform,pipeline,docs/decisions,diagrams}
# main.tf, variables.tf, apis.tf, iam.tf, storage.tf, database.tf, secrets.tf
# pipeline/{ingest,chunk,embed,generate}.py

---

## Phase 1 — Terraform: Infrastructure

Built and reviewed one file at a time.

### Step 5 — main.tf
GCS backend (bucket `rag-pipeline-501417-state`, hardcoded), provider config
including the `random` provider (needed for `random_password` in database.tf)

### Step 6 — variables.tf
project_id, region, zone defaults hardcoded; separate `ingestion_bucket_name`
variable = `rag-pipeline-501417-ingestion`

### Step 7 — apis.tf
aiplatform, sqladmin, storage, documentai, logging, monitoring, iam,
secretmanager — `disable_on_destroy = false`

### Step 8 — iam.tf
Service account `rag-pipeline-501417-pipeline`:
storage.objectAdmin, aiplatform.user, cloudsql.client, logging.logWriter,
monitoring.metricWriter, documentai.apiUser

### Step 9 — storage.tf
Ingestion bucket (separate from state bucket), versioning enabled,
`force_destroy = true`

### Step 10 — database.tf
Cloud SQL Postgres 15 instance `rag-pipeline-501417-pg`, database `ragdb`,
user `rag_pipeline`. Password via `random_password` resource — never a
Terraform variable.

> No `cloudsql.enable_pgvector` database flag — doesn't exist. pgvector on
> Postgres 15 needs only `CREATE EXTENSION vector;` after provisioning.

### Step 11 — secrets.tf
Password stored in Secret Manager as `rag-pipeline-501417-db-password`;
pipeline SA granted `secretAccessor`

### Step 12 — Monitoring deliberately excluded from Terraform
Alert policies are a weak IaC candidate — iterative, console-tuned resources.
Moved to Cloud Console setup (Phase 6).

### Step 13 — terraform apply

---

## Phase 2 — Database Setup

### Step 14 — Enable pgvector

Cloud SQL Auth Proxy or Console query editor:

CREATE EXTENSION vector;

### Step 15 — Start Cloud SQL Auth Proxy (separate Cloud Shell tab, keep running)

./cloud-sql-proxy rag-pipeline-501417:europe-west2:rag-pipeline-501417-pg

All pipeline scripts connect to `127.0.0.1:5432` — never the public IP.

---

## Phase 3 — Data Setup

### Step 16 — Upload source PDFs

gsutil cp your-file.pdf gs://rag-pipeline-501417-ingestion/

Two cover letter PDFs used as source documents for this PoC.

---

## Phase 4 — Pipeline (Stage by Stage)

Built and tested one script at a time, each runnable standalone and
chaining off the previous stage's function when run directly.

### Step 17 — ingest.py (Stage 1 — Ingestion)

- Lists all `.pdf` blobs in the ingestion bucket
- Downloads each to a temp file, loads via `PyPDFLoader`
- Overwrites `source` metadata to point back at `gs://bucket/blob`, not the
  local temp path — critical for citations to be meaningful later
- Returns a flat list of `Document` objects, one per page

python ingest.py
# prints total pages loaded + preview of first page

### Step 18 — chunk.py (Stage 2 — Chunking)

- `RecursiveCharacterTextSplitter`, `chunk_size=1000`, `chunk_overlap=150`
- Separators: `["\n\n", "\n", ". ", " ", ""]`
- Metadata (including `source`) preserved on every chunk
- Pure Python — no GCP calls in this stage

python chunk.py
# chains off ingest.py, prints chunk count + sample chunk

### Step 19 — embed.py (Stage 3 & 4 — Embedding + Indexing)

- `VertexAIEmbeddings` with `text-embedding-004`
- DB password fetched from Secret Manager at runtime — never hardcoded
- Connection string built as `postgresql+psycopg://...@127.0.0.1:5432/ragdb`
  (proxy address, not public IP)
- `PGVector` from `langchain_postgres`, collection name `rag_poc_chunks`,
  `use_jsonb=True`
- `vectorstore.add_documents(chunks)` embeds and upserts in one call

python embed.py
# chains ingest → chunk → embed, prints number of chunks stored

### Step 20 — Verify in psql

\c ragdb
SELECT COUNT(*) FROM langchain_pg_embedding;
-- confirmed: 8 chunks stored across both PDFs

### Step 21 — generate.py (Stage 5, 6, 7 — Retrieval + Augmentation + Generation)

- Retriever: `vectorstore.as_retriever(search_kwargs={"k": TOP_K})`, `TOP_K=4`
- Prompt instructs the model to answer only from context, and to say so
  explicitly if context is insufficient rather than guessing
- Generation model: `gemini-2.5-flash` (`gemini-2.0-flash-001` was
  discontinued June 2026 — swapped after initial build)
- LCEL chain: `{context: retriever | format_docs_with_sources, question:
  RunnablePassthrough()} | prompt | llm | StrOutputParser()`
- `format_docs_with_sources` tags each retrieved chunk with its GCS source
  in the context block, so citations are traceable end to end
- Structured logging via `google.cloud.logging` client — emits an
  `insufficient_context` event when the LLM's answer contains phrases like
  "not enough information" or "cannot answer." This replaced an earlier,
  weaker zero-document-retrieval trigger (a query can retrieve documents
  and still be poorly grounded — the phrase heuristic on the actual answer
  is a better quality proxy than counting retrieved docs)

python generate.py
# ask a question grounded in one PDF, one grounded in the other,
# and one with no grounding in either — confirms multi-source
# discrimination and correct refusal behaviour

---

## Phase 5 — End-to-End Validation

### Step 22 — Confirmed results
- 8 chunks stored across both PDFs
- Correct multi-source retrieval discrimination (questions answered from
  the right source document)
- Correct grounded refusal on out-of-scope questions

---

## Phase 6 — Monitoring (Console, not Terraform)

### Step 23 — Log-based metric

Created in Console: `rag-pipeline-zero-retrieval-queries`, sourced from the
`insufficient_context` structured log events.

### Step 24 — Alert policy (in progress / outstanding)

Metric picker in the alert policy console did not surface the custom
log-based metric on first attempt — troubleshooting was paused here.
**Known follow-up**, not yet resolved.

---

## Phase 7 — Outstanding (Next Steps)

- Resolve alert policy metric picker issue, complete monitoring setup
- RAGAS evaluation (deliberately sequenced after monitoring, per your stated
  preference)

---

## Teardown

cd terraform
terraform destroy
gsutil rm -r gs://$BUCKET_NAME
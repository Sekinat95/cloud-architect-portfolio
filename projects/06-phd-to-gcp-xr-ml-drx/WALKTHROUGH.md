# PhD Research Replication — XR Network Traffic Prediction (LSTM + GP)

Full MLOps pipeline replicating PhD research: predicting XR packet arrival
times using LSTM (PyTorch) and Gaussian Process Regression (scikit-learn)
in parallel, on Vertex AI.

---

## Phase 0 — Setup

### Step 1 — Environment Variables

export PROJECT_ID=phd-to-gcp-xr-ml-drx
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

mkdir -p projects/06-phd-to-gcp-xr-ml-drx/{terraform,pipeline/components,docs/decisions,diagrams}
# main.tf, variables.tf, outputs.tf, storage.tf, iam.tf, bigquery.tf
# pipeline/components/{preprocessing,lstm_training,gp_training,evaluate,model_upload,batch_inference}.py
# pipeline/{pipeline,run_pipeline}.py, cloudbuild.yaml

---

## Phase 1 — Architecture Decision

Two models trained in parallel on the same preprocessed data, both predicting
`Time(t)` from `Time(t-1)` as a first pass (PhD's original GP config used
`interarrival_time` as target — noted for a later precision-matching rerun):

- **LSTM** (PyTorch) — sequential/recurrent approach
- **GP Regressor** (scikit-learn) — non-parametric probabilistic approach

No gating between them — both always proceed to registration. The point is
side-by-side RMSE comparison across paradigms, not selecting a winner
(this mirrors ADR-003's reasoning from Project 04/05: a gate implies a
candidate to reject, and here there isn't one).

Four buckets, separated by concern:
- raw-data — source CSVs
- processed-data — preprocessed train/test arrays (separate from model artefacts)
- model-artefacts — trained model files
- pipeline-root — Vertex AI Pipelines component I/O

---

## Phase 2 — Terraform: Infrastructure

### Step 5 — main.tf
- Backend bucket name hardcoded
- APIs: aiplatform, bigquery, bigquerystorage, cloudbuild, cloudscheduler,
  compute, iam, cloudresourcemanager, secretmanager, storage
- `time_sleep` 120s after API enablement

### Step 6 — storage.tf
Four buckets (raw-data, processed-data, model-artefacts, pipeline-root),
`force_destroy = true` on all

### Step 7 — iam.tf
`full-mlops-pipeline-sa` — aiplatform.user, storage.admin,
bigquery.dataEditor, bigquery.jobUser, iam.serviceAccountUser (self)

### Step 8 — bigquery.tf
Single dataset `xr_predictions`, two tables sharing one schema:
`lstm_predictions`, `gp_predictions`
(sample_index, time_t_minus_1, actual_time_t, predicted_time_t, residual,
squared_error, app, run_id, run_timestamp, model_version)

### Step 9 — terraform apply

---

## Phase 3 — Data

### Step 10 — Upload source CSVs

`concatenated_df_DN_train.csv`, `concatenated_df_DN_test.csv` → raw-data bucket
(contains packet timing data across 5 XR apps: beat_saber, vr_chat, google_E,
rec_room, half_life)

---

## Phase 4 — Pipeline Components

### Step 11 — preprocessing.py

Two divergent preprocessing paths from the same source data:
- **LSTM path**: lookback-windowed sequences (lookback=1), scaled, saved as
  `.npy` — App column stored as a **separate** `.npy` array, not fed to the
  model, only reattached at batch-inference time for BigQuery annotation
  and per-app RMSE slicing
- **GP path**: random sample of `gp_n_samples` (50,000 rows), 70/30 train/test
  split (`gp_train_prop=0.7`)

### Step 12 — lstm_training.py
PyTorch LSTM: `input_size=1, hidden_size=200, num_stacked_layers=1,
batch_size=128, num_epochs=600, learning_rate=0.004`
Outputs: `model.pt`, `lstm_scaler.pkl` (batch inference), plus `model.mar`
(TorchServe format, for Vertex AI Model Registry's PyTorch prebuilt container)

### Step 13 — gp_training.py
scikit-learn GaussianProcessRegressor: `n_restarts_optimizer=10, normalize_y=True`
Output: `model.pkl` (sklearn prebuilt container)
Resource request: `.set_memory_request("40G").set_memory_limit("52G")
.set_cpu_request("7").set_cpu_limit("8")` — GP fitting over 50,000 samples
is memory-hungry; default KFP resources are insufficient

### Step 14 — evaluate.py
No gating logic — reads train/test RMSE from both models' metrics outputs
and logs them side by side in one KFP Metrics artifact, visible together
in the Vertex AI Pipelines UI. Both models always proceed to upload.

### Step 15 — model_upload.py
Registers both LSTM and GP models in Vertex AI Model Registry, tagged with
`pipeline_run_id`. Runs after evaluate (`upload_task.after(evaluate_task)`).

### Step 16 — batch_inference.py
Runs after upload completes (`batch_task.after(upload_task)`). For each model:
inverse-transforms scaled predictions back to real values, computes residuals
and squared errors, reattaches the App column, writes to its BigQuery table.

---

## Phase 5 — Pipeline Assembly (pipeline.py)

DAG: preprocessing → {lstm_training, gp_training} (parallel) → evaluate →
model_upload → batch_inference

Caching set to `True` in `run_pipeline.py` — reruns skip already-completed
steps with unchanged inputs (useful given the GPU debugging cycle below).

---

## Phase 6 — GPU Attempt (documented failure, resolved on CPU)

### Step 17 — First attempt: GPU via CustomTrainingJobOp

lstm_training_job = create_custom_training_job_from_component(
    lstm_training,
    machine_type="n1-standard-4",
    accelerator_type="NVIDIA_TESLA_T4",
    accelerator_count=1,
)

Failed: `RESOURCE_EXHAUSTED —
aiplatform.googleapis.com/custom_model_training_nvidia_t4_gpus`

### Step 18 — Diagnose: preemptible quota exists, but isn't reachable

Preemptible T4 quota = 1 in europe-west2, but neither plain KFP tasks nor
`create_custom_training_job_from_component` expose a way to route to the
preemptible pool — it requires a custom job spec KFP v2 doesn't cleanly
support. Confirmed via direct retry: same `RESOURCE_EXHAUSTED` error,
proving it did not auto-route to preemptible.

### Step 19 — Decision: run LSTM on CPU at full epoch count

Rejected the "10 epochs on CPU just to get the pipeline working" shortcut —
a 10-epoch model is not a valid result, and the point is a working *and
meaningful* pipeline, not just a green checkmark. Ran the full 600 epochs
on CPU instead (`n1-standard-4`, no accelerator).

Backup: `gs://phd-to-gcp-xr-ml-drx-model-artefacts/lstm/model_backup_600epochs/`

---

## Phase 7 — Execution

### Step 20 — Run pipeline

cd pipeline
python pipeline.py
python run_pipeline.py

### Step 21 — Verify completion, all 6 stages

Preprocessing → LSTM training (CPU, 600 epochs) → GP training (n=10,000)
→ Evaluate → Model upload (both registered) → Batch inference (both tables written)

### Step 22 — Check row counts

bq query --use_legacy_sql=false \
  'SELECT COUNT(*) FROM `phd-to-gcp-xr-ml-drx.xr_predictions.lstm_predictions`'
bq query --use_legacy_sql=false \
  'SELECT COUNT(*) FROM `phd-to-gcp-xr-ml-drx.xr_predictions.gp_predictions`'

Result: LSTM 45,157 rows (full test set), GP 3,000 rows (30% of 10,000).

### Step 23 — Results (Vertex AI Pipelines UI → evaluate node → metrics tab)

**LSTM — overall RMSE 12.94**, per app: beat_saber 0.35, vr_chat 5.28,
google_E 14.21, rec_room 18.06, half_life 42.42
(wide per-app spread — worth a note in ADD as an observation, not yet
root-caused)

**GP — RMSE 0.063** on beat_saber only (the 10,000-row random sample only
drew beat_saber rows — sampling artefact to flag, not a real cross-app result)

---

## Phase 8 — CI/CD

### Step 24 — cloudbuild.yaml

Same pattern as Project 04/05: compile + submit pipeline in one `bash -c`
step (pip installs don't persist between Cloud Build steps), then copy
`pipeline.yaml` to `gs://phd-to-gcp-xr-ml-drx-pipeline-root/compiled/`.
Trigger service account: `full-mlops-pipeline-sa`.

---

## Teardown

cd terraform
terraform destroy
gsutil rm -r gs://$BUCKET_NAME
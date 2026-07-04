"""
deploy_endpoints.py

Deploys LSTM and GP models from Vertex AI Model Registry to separate
Vertex AI Endpoints for online serving and model monitoring.

Run from the serving/ directory:
    cd ~/cloud-architect-portfolio/projects/06-phd-to-gcp-xr-ml-drx/inference
    python deploy_endpoints.py
"""

from google.cloud import aiplatform

# ------------------------------------------------------------------ #
# Config
# ------------------------------------------------------------------ #
PROJECT_ID = "phd-to-gcp-xr-ml-drx"
REGION = "europe-west2"

LSTM_MODEL_ID = "6017684313422692352"
GP_MODEL_ID = "629690309227315200"

aiplatform.init(project=PROJECT_ID, location=REGION)

# ------------------------------------------------------------------ #
# Step 1 — Deploy LSTM model to endpoint
# ------------------------------------------------------------------ #
print("Creating LSTM endpoint...")
lstm_endpoint = aiplatform.Endpoint.create(
    display_name="lstm-arrival-time-endpoint",
    project=PROJECT_ID,
    location=REGION,
)
print(f"LSTM endpoint created: {lstm_endpoint.resource_name}")

print("Deploying LSTM model to endpoint...")
lstm_model = aiplatform.Model(model_name=LSTM_MODEL_ID)
lstm_endpoint.deploy(
    model=lstm_model,
    deployed_model_display_name="lstm-arrival-time",
    machine_type="n1-standard-2",
    min_replica_count=1,
    max_replica_count=1,
    traffic_percentage=100,
)
print(f"LSTM model deployed to endpoint: {lstm_endpoint.resource_name}")

# ------------------------------------------------------------------ #
# Step 2 — Deploy GP model to endpoint
# ------------------------------------------------------------------ #
print("Creating GP endpoint...")
gp_endpoint = aiplatform.Endpoint.create(
    display_name="gp-arrival-time-endpoint",
    project=PROJECT_ID,
    location=REGION,
)
print(f"GP endpoint created: {gp_endpoint.resource_name}")

print("Deploying GP model to endpoint...")
gp_model = aiplatform.Model(model_name=GP_MODEL_ID)
gp_endpoint.deploy(
    model=gp_model,
    deployed_model_display_name="gp-arrival-time",
    machine_type="n1-standard-2",
    min_replica_count=1,
    max_replica_count=1,
    traffic_percentage=100,
)
print(f"GP model deployed to endpoint: {gp_endpoint.resource_name}")

# ------------------------------------------------------------------ #
# Step 3 — Print endpoint resource names for use in monitoring setup
# ------------------------------------------------------------------ #
print("\n=== Endpoint Resource Names ===")
print(f"LSTM endpoint: {lstm_endpoint.resource_name}")
print(f"GP endpoint:   {gp_endpoint.resource_name}")
print("\nSave these for setup_monitoring.py")
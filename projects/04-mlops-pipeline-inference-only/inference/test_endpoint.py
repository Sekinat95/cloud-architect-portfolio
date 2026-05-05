"""
Deploys the registered FinBERT model to a Vertex AI Endpoint,
runs test predictions, then deletes the endpoint.
"""
from google.cloud import aiplatform

PROJECT_ID = "mlops-pipeline-inference-only"
REGION = "europe-west2"
MODEL_ID = "86531565105971200"

TEST_SENTENCES = [
    "The company reported record profits this quarter.",
    "The firm filed for bankruptcy following years of losses.",
    "The annual general meeting will be held on Friday.",
    "Revenue increased by 40% year on year driven by strong demand.",
    "The CEO resigned amid mounting pressure from shareholders."
]

def main():
    aiplatform.init(project=PROJECT_ID, location=REGION)

    model = aiplatform.Model(model_name=MODEL_ID)
    print(f"Model: {model.display_name}")

    print("Creating endpoint...")
    endpoint = aiplatform.Endpoint.create(
        display_name="finbert-inference-endpoint",
        project=PROJECT_ID,
        location=REGION
    )

    print("Deploying model — this takes ~10 minutes...")
    model.deploy(
        endpoint=endpoint,
        deployed_model_display_name="finbert-deployed",
        machine_type="n1-standard-4",
        min_replica_count=1,
        max_replica_count=1,
        sync=True
    )

    print("Model deployed. Running test predictions...")
    for sentence in TEST_SENTENCES:
        response = endpoint.predict(instances=[{"text": sentence}])
        prediction = response.predictions[0]
        print(f"\nInput:  {sentence}")
        print(f"Output: {prediction}")

    print("\nUndeploying and deleting endpoint...")
    endpoint.undeploy_all()
    endpoint.delete()
    print("Endpoint deleted.")

if __name__ == "__main__":
    main()

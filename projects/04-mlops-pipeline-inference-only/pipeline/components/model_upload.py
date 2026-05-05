from kfp.dsl import component

@component(
    base_image="python:3.10",
    packages_to_install=["google-cloud-aiplatform"]
)
def model_upload(
    project_id: str,
    region: str,
    pipeline_run_id: str
) -> str:
    """
    Registers ProsusAI/finbert in Vertex AI Model Registry.
    Uses HuggingFace PyTorch DLC — no GCS model upload needed.
    Model is pulled from HuggingFace Hub at serving time.
    """
    from google.cloud import aiplatform

    CONTAINER_URI = "us-docker.pkg.dev/deeplearning-platform-release/gcr.io/huggingface-pytorch-inference-cu121.2-2.transformers.4-44.ubuntu2204.py311"

    aiplatform.init(project=project_id, location=region)

    uploaded_model = aiplatform.Model.upload(
        display_name=f"finbert-inference-{pipeline_run_id}",
        serving_container_image_uri=CONTAINER_URI,
        serving_container_environment_variables={
            "HF_MODEL_ID": "ProsusAI/finbert",
            "HF_TASK": "text-classification",
        },
        serving_container_ports=[8080],
        description="ProsusAI/finbert pretrained financial sentiment classifier.",
        labels={
            "model": "finbert",
            "framework": "pytorch",
        }
    )

    print(f"Model registered: {uploaded_model.resource_name}")
    return uploaded_model.resource_name

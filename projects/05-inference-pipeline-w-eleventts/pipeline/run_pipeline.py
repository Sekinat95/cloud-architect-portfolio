from google.cloud import aiplatform
import uuid
#import os

#PROJECT_ID = os.environ["PROJECT_ID"]
PROJECT_ID = "inference-pipeline-w-eleventts"
REGION = "europe-west2"
PIPELINE_ROOT = f"gs://{PROJECT_ID}-pipeline-root"
SERVICE_ACCOUNT = f"mlops-pipeline-sa@{PROJECT_ID}.iam.gserviceaccount.com"

RUN_ID = f"run-{uuid.uuid4().hex[:8]}"

def main():
    aiplatform.init(project=PROJECT_ID, location=REGION)

    job = aiplatform.PipelineJob(
        display_name=f"finbert-inference-{RUN_ID}",
        template_path=f"gs://{PROJECT_ID}-pipeline-root/compiled/pipeline.yaml",
        pipeline_root=PIPELINE_ROOT,
        parameter_values={"pipeline_run_id": RUN_ID},
        enable_caching=False
    )

    print(f"Submitting pipeline run: {RUN_ID}")
    job.submit(service_account=SERVICE_ACCOUNT)
    print(f"Pipeline submitted: {RUN_ID}")
    print(f"Monitor: https://console.cloud.google.com/vertex-ai/pipelines?project={PROJECT_ID}")

if __name__ == "__main__":
    main()

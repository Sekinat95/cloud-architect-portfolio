"""
One-off script: downloads Financial PhraseBank (sentences_allagree)
from the zip file and uploads to GCS as CSV.
"""

import pandas as pd
from google.cloud import storage
import io
import requests
import zipfile
import tempfile
import os

PROJECT_ID = "mlops-pipeline-inference-only"
BUCKET_NAME = f"{PROJECT_ID}-raw-data"
DESTINATION_BLOB = "financial_phrasebank/sentences_allagree.csv"

ZIP_URL = "https://huggingface.co/datasets/takala/financial_phrasebank/resolve/main/data/FinancialPhraseBank-v1.0.zip"
TARGET_FILE = "Sentences_AllAgree.txt"

# Label mapping: text file uses @positive, @negative, @neutral suffix
LABEL_MAP = {"positive": "positive", "negative": "negative", "neutral": "neutral"}

def download_and_parse(zip_url: str, target_file: str) -> pd.DataFrame:
    print(f"Downloading zip from Hugging Face...")
    r = requests.get(zip_url, headers={"User-Agent": "Mozilla/5.0"}, allow_redirects=True)
    print(f"Status: {r.status_code}, Size: {len(r.content)} bytes")
    r.raise_for_status()

    rows = []
    with zipfile.ZipFile(io.BytesIO(r.content)) as z:
        print(f"Files in zip: {z.namelist()}")
        # Find the target file (may be in a subfolder)
        match = [f for f in z.namelist() if target_file in f]
        if not match:
            raise RuntimeError(f"{target_file} not found in zip. Files: {z.namelist()}")
        print(f"Reading: {match[0]}")
        with z.open(match[0]) as f:
            for line in f.read().decode("latin-1").splitlines():
                line = line.strip()
                if not line:
                    continue
                # Format: "sentence text@label"
                parts = line.rsplit("@", 1)
                if len(parts) == 2:
                    sentence, label = parts[0].strip(), parts[1].strip().lower()
                    rows.append({"sentence": sentence, "label": label})

    df = pd.DataFrame(rows)
    return df

def upload_to_gcs(df: pd.DataFrame, bucket_name: str, blob_name: str):
    client = storage.Client(project=PROJECT_ID)
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(blob_name)
    buffer = io.BytesIO()
    df.to_csv(buffer, index=False)
    buffer.seek(0)
    blob.upload_from_file(buffer, content_type="text/csv")
    print(f"Uploaded {len(df)} rows to gs://{bucket_name}/{blob_name}")

def main():
    df = download_and_parse(ZIP_URL, TARGET_FILE)
    print(f"Shape: {df.shape}")
    print(f"Label distribution:\n{df['label'].value_counts()}")
    print(f"Sample:\n{df.head(3)}")
    upload_to_gcs(df, BUCKET_NAME, DESTINATION_BLOB)

if __name__ == "__main__":
    main()

import os
from google.cloud import aiplatform
from elevenlabs.client import ElevenLabs
from elevenlabs import save

# --- Config ---
PROJECT_ID = "inference-pipeline-w-eleventts"
REGION = "europe-west2"
ENDPOINT_ID = ""  # from test_endpoint.py output
ELEVENLABS_API_KEY = os.environ["ELEVENLABS_API_KEY"]

# --- Init clients ---
aiplatform.init(project=PROJECT_ID, location=REGION)
endpoint = aiplatform.Endpoint(endpoint_name=f"projects/{PROJECT_ID}/locations/{REGION}/endpoints/{ENDPOINT_ID}")

el_client = ElevenLabs(api_key=ELEVENLABS_API_KEY)

def classify_and_speak(sentence: str, output_path: str = "output.mp3"):
    # 1. Classify via FinBERT endpoint
    response = endpoint.predict(instances=[{"text": sentence}])
    predictions = response.predictions[0]
    label = predictions["label"]
    confidence = round(predictions["score"] * 100, 1)

    # 2. Build TTS string
    tts_text = (
        f"Sentence: {sentence}. "
        f"Sentiment classification: {label}. "
        f"Model confidence: {confidence} percent."
    )
    print(f"TTS input: {tts_text}")

    # 3. Generate audio
    audio = el_client.generate(
        text=tts_text,
        voice="Rachel",       # or any voice from your ElevenLabs account
        model="eleven_monolingual_v1"
    )

    # 4. Save
    save(audio, output_path)
    print(f"Audio saved to {output_path}")

if __name__ == "__main__":
    sentences = [
        "The company reported record profits this quarter.",
        "The firm filed for bankruptcy following years of losses.",
        "The annual general meeting will be held on Friday."
    ]
    for i, s in enumerate(sentences):
        classify_and_speak(s, output_path=f"output_{i}.mp3")
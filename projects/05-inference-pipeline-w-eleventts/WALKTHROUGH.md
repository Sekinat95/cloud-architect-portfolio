# WALKTRHOUGH - INFERENCE PIPELINE PLUS ELEVENLAB TTS INTEGRATION

This piggybacks off of the [inference pipeline for financial sentiments analysis](/projects/04-mlops-pipeline-inference-only/WALKTHROUGH.md)

The text to speech integration was included at the the point of online inference usign vertex AI endpoint and it proceeds as follows:

Deploy endpoint (reused across runs — not redeployed each time)
         │
         ▼
For each of 5 test sentences:
  1. endpoint.predict(instances=[{"text": sentence}])
     → prediction = {label, score}
  2. Build spoken text:
     "Sentence: {sentence}. Sentiment: {label}. Confidence: {confidence}%."
  3. el_client.text_to_speech.convert(
         text=tts_text,
         voice_id="pNInz6obpgDQGcFmaJgB",   # Adam — Rachel unavailable on free tier
         model_id="eleven_turbo_v2_5",       # eleven_monolingual_v1 deprecated
         output_format="mp3_44100_128"
     )
     → returns a generator of audio chunks (not a single object — SDK changed
       from el_client.generate() to .text_to_speech.convert())
  4. Write chunks to output_{i}_{label}.mp3:
     with open(output_path, "wb") as f:
         for chunk in audio:
             f.write(chunk)
         │
         ▼
After all 5 sentences processed:
  endpoint.undeploy_all()
  endpoint.delete()
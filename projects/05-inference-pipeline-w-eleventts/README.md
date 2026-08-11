# FINANCIAL SENTIMENTS ANALYSIS INFERENCE PIPELINE WITH ELEVENLABS TEXT TO SPEECH (TTS) API

## Introduction
This continues from financial sentiments analysis pipeline and integrates a text to speech API (elevenlabsTTS) on top of the serving request response to generate audio files of the inference results. The overall architecture is as follows
## Architecture Overview

```mermaid
graph TD
  GCS["Raw Financial Data"] --> VAPL
    subgraph VAPL["the pipeline"]
      DV["Data validation component"] --> PPR
      PPR["Preprocessing component"] --> BINF["FinBERT predictions"] --> OUT
      OUT["Bigquery <br/> Batch results"] --> MDLU
      MDLU["Model Upload <br/> VA Model Registry"] --> DP
      DP["VA endpoint <br/> online serving"]
    end
    subgraph TEST["send live requests <br/> test_endpoint.py"]
    end
    subgraph TTS["ElevenLabs <br/> TTS API"]
    end
    subgraph TRDWN["Tear down"]
    end
   VAPL --> TEST --> TTS --> TRDWN
```
# TTS Voice Research Notes

> Research conducted 2026-03-10. Reference for future TTS implementation decisions.

## Current approach: macOS `say` with system default voice

The `say` command is invoked **without `-v`** so it uses the system default voice. When the system default is set to **Siri Voice 2** (via System Settings > Accessibility > Spoken Content), this produces natural, high-quality speech at zero cost.

### Why no `-v` flag?

Siri voices (e.g., "Siri Voice 2") are NOT available through the `say -v` parameter or `AVSpeechSynthesizer` API. They don't appear in `say -v '?'` output. Apple restricts them intentionally. The ONLY way to use them is as the system default voice with no `-v` parameter.

The internal voice ID is `com.apple.siri.natural.Simone` (stored in `com.apple.Accessibility` defaults under `SpokenContentDefaultVoiceSelectionsByLanguage`).

### macOS `say` voice tiers (from `say -v '?'`)

| Tier | Example | Quality |
|------|---------|---------|
| Standard | Samantha, Fred, Kathy | Robotic |
| Enhanced | Tom (Enhanced) | Better, still synthetic |
| Premium | Ava (Premium) | Good, but not Siri-level |
| Siri (system default only) | Siri Voice 2 | Natural, best quality |

## FOSS TTS alternatives evaluated

| Engine | Quality vs Siri | macOS Support | License | Key Risk |
|--------|----------------|---------------|---------|----------|
| Kokoro TTS (hexgrad) | ~85-92% | Good (Apple Silicon via MLX-Audio) | Apache 2.0 | Single anonymous maintainer; PyTorch pickle format can execute arbitrary code on model load |
| Piper TTS (rhasspy/OHF) | ~75-80% | Native ARM64 binary | GPL-3.0 (new fork) | Original repo archived Oct 2025; GPL license incompatible with closed-source |
| F5-TTS | Excellent | Poor (known audio issues on macOS) | - | Requires reference audio; macOS-specific bugs |
| StyleTTS2 | Excellent | Moderate | - | Complex setup |
| Bark (Suno) | Very natural | Poor | - | Requires 12GB VRAM |
| XTTS-v2 (Coqui) | Great | Moderate | - | Coqui shutdown Jan 2024; fragmented forks |

## Enterprise/commercial TTS options

- **Cartesia AI** -- Already has a TRC page at UWM (reviewed Sept 2025). Used by the MIA (Most Intelligent Agent) project for real-time voice in call handlers. Ultra-low-latency, natural-sounding. Commercial API. Recommended long-term path -- already vetted internally.
- **Google Cloud TTS** -- Also used by MIA project (via "SmartTalk"). Has TRC presence.
- **ElevenLabs** -- Popular commercial option. Not yet in TRC.
- **Azure Speech** -- Microsoft offering. Not yet confirmed in TRC.

## Security comparison: Kokoro vs Piper

Neither appears in TRC or ServiceNow CMDB. Neither has known CVEs.

**Kokoro risks:** Unknown maintainer identity, PyTorch pickle deserialization (code execution on model load), very new project (~15 months), no security policy.

**Piper risks:** GPL-3.0 license (copyleft), maintainer transition to Open Home Foundation (uncertain commitment), some unexplained firewall issues reported.

**For internal tooling:** Piper is safer (ONNX format can't execute code, more mature).
**For commercial products:** Kokoro wins on licensing (Apache 2.0) but loses on model safety.

## Recommendation path

1. **Now (POC):** Use `say -o` with no `-v` flag (Siri Voice 2 via system default). Zero cost, zero installs.
2. **Future (production):** Evaluate Cartesia AI -- already TRC-reviewed, used by MIA team. Contact the LOA/MIA team for implementation patterns.

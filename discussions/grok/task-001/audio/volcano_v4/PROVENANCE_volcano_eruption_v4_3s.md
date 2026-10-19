# PROVENANCE: volcano_eruption_v4_3s.wav

## File
- Name: volcano_eruption_v4_3s.wav
- SHA-256: e14235fd8ae7af0f3ec0565053fa1c21885e7fd4f057a7f2a91c43dcb25ada4d
- Size: 297644 bytes
- Format: WAV PCM16 (pcm_s16le), 48000 Hz, mono, 3.100 s
- Created: 2026-10-19, ~04:36 Europe/Sofia, on Grok Bot's Linux box, in /workspace/t9/play/
- Delivered: in Grok Bot chat on 2026-10-19 (reply to "samo s 1 bas, poveche otlomki")
- Status: trial sound effect. NOT integrated into the game, NOT approved by a human.

## Generator / recipe
- File: generate_volcano_eruption_v4_3s.py (SHA-256 fa9c6ecc795024a66d75398e3e514c36c67e7039be4b99cfce8f846202615797)
- Environment: Python 3.13.5, numpy 2.5.4. No other libraries.
- Seed: numpy default_rng(91)
- Layers:
  1. Rumble: noise band-passed to 20-120 Hz, rises over 0.6 s, decays with tau 1.2 s, with a 3-12 Hz shake.
  2. One bass hit at 0.6 s: sine sweeping down from 188 to 38 Hz, plus a 60-1800 Hz noise burst.
  3. Lava roar: 60-500 Hz noise with slow modulation and tanh saturation. Hiss: 2.5-7 kHz noise, very quiet.
  4. Debris: 380 small grains (500-6000 Hz) and 45 larger chunks (150-1500 Hz), with exponential decay.
  5. Normalized to -1.5 dBFS peak, with a 0.4 s fade-out at the end.
- Published for review as generate_volcano_eruption_v4_3s.py.txt (text only, not executable here).
- Exactness note: the delivered WAV was produced by an inline (heredoc) script run on 2026-10-19 ~04:36. After delivery that code was saved to a .py file verbatim, except for 2 added lines (import sys / output-path argument) and the output path; synthesis code is unchanged.
- Reproducibility check (done ONCE on 2026-10-19 ~04:46 Europe/Sofia, BEFORE the REPORTS_ONLY grant instruction): the saved script wrote to a separate temp file /tmp/rebuild.wav, whose SHA-256 was byte-identical (e14235fd…da4d). The delivered file was NOT regenerated or modified. The generator has not been run since.

## Samples
- Third-party samples: NONE. Everything is synthesized mathematically from noise and sine waves.
- Old GnomiT reference samples (OLD_REFERENCE/): NOT used, not read into the generator.
- Internet downloads: NONE.

## Terms
- Third-party sample licenses: not applicable (no samples).
- Software: Python (PSF License), numpy (BSD-3-Clause). The output does not contain their code.
- Legal ownership and license of the AI-generated output: UNKNOWN. No license has been set for it.
- Human approval: UNKNOWN / not given.

## Relationship to V1
- V1 (GNOMIT_GROK_AUDIO_TRIAL_V1.zip, SHA 9267e4a5…5fba) contains 03_eruption (1.65 s), made with generate_gnomit_sfx.py.
- volcano_eruption_v4_3s.wav is NOT part of V1 or V2. It is a separate chat iteration (v1 1.1 s, then v2, v3, v4) with its own new code.
- It does NOT use V1's generator code or audio. It uses the same methods (numpy noise and sine synthesis) and the same format.
- Whether it replaces V1's 03_eruption: UNKNOWN (that is a human decision).

## Publication
- Repo Fuet-Goat/GnomiT-review-test, branch codex/grok/task-001, folder discussions/grok/task-001/audio/volcano_v4/. Grant REPORTS_ONLY: the WAV and an executable .py are deliberately NOT committed.

## Unknown
- Ownership/license of the output: UNKNOWN.

---
name: osint-ai-content
description: Verifikation af AI-genereret indhold — deepfake-detektion, GAN-face-detektion, AI-tekst-detektion, C2PA Content Credentials, voice-cloning-checks. Brug ved spørgsmål om "deepfake", "AI-generated", "GAN face", "synthetic media", "C2PA", "Content Credentials", "voice clone", "AI text detection" eller når et artefakt er mistænkt for at være AI-skabt.
---

# AI-Content Verification (OSINT)

Brug denne skill når et billede, en video, en stemme eller en tekst
muligvis er AI-genereret eller manipuleret. Komplementerer
`osint-image-analysis` — fokus her er specifikt på syntetisk media.

## Workflow

1. **Provenance først.** Tjek for C2PA Content Credentials i metadata
   (Adobe/OpenAI/Microsoft signerer ofte). Hvis gyldig signatur =
   stærk attribution.
2. **Reverse provenance.** Reverse image-/video-search → ælde
   indikerer "ikke AI" hvis den findes præ-2022.
3. **Visuel detektion (billede).** Tjek for GAN-fingerprints
   (asymmetriske øjne, smeltede ører, baggrund-glitches, ulogiske
   tekst-elementer i scenen).
4. **Algoritmisk detektion.** Kør gennem 2+ uafhængige detektorer —
   ingen alene er pålidelig (~70-90% TPR med høj FPR).
5. **Video-specifikt.** Tjek læbe-synkronisering, blink-rate
   (ægte mennesker blinker 15-20×/min; gamle deepfakes mindre),
   konsistens af lyssætning på tværs af frames.
6. **Audio-specifikt.** Spektral-analyse for unaturlige hop,
   manglende baggrundsstøj-konsistens, robotagtige formant-mønstre.
7. **Tekst-detektion.** Perplexity- og burstiness-analyse (Pangram,
   GPTZero). **Stor advarsel:** disse er notoriskt upålidelige —
   producerer ofte falske positiver på ikke-native engelsk-tekst
   eller formel skrivning.
8. **Konkludér med usikkerheds-margen.** Kald aldrig noget
   "definitivt AI" baseret på én detektor.

## Værktøjer

*Provenance & Content Credentials:*
- [C2PA Tool](https://github.com/contentauth/c2pa-rs) – CLI til at læse C2PA-manifests.
- [Content Credentials Verify](https://contentcredentials.org/verify) – Web-tool fra CAI.
- [Adobe Verify](https://verify.contentauthenticity.org/) – Adobe's web-verifier.

*Deepfake / image AI-detection:*
- [Hugging Face spaces — AI image detectors](https://huggingface.co/spaces?search=ai+detector) – Bredt udvalg af community-modeller.
- [Hive Moderation Deepfake](https://hivemoderation.com/ai-generated-content-detection) – Kommerciel API.
- [Sensity](https://sensity.ai/) – Deepfake-detection (kommerciel).
- [Reality Defender](https://realitydefender.com/) – Multi-modal AI-detektion.
- [Optic AI or Not](https://www.aiornot.com/) – Hurtig web-check.

*Video-analyse:*
- [Microsoft Video Authenticator](https://www.microsoft.com/en-us/ai/responsible-ai/video-authenticator) – Forsker-tool.
- [InVID Verification Plugin](https://www.invid-project.eu/tools-and-services/invid-verification-plugin/) – Frame-extraction + reverse-search.
- [Deepware Scanner](https://scanner.deepware.ai/) – Video deepfake-detection.

*Audio / voice clone:*
- [AntiFake](https://github.com/WUSTL-CSPL/AntiFake) – Voice-clone-detektion (forskning).
- [pindrop](https://www.pindrop.com/) – Voice-fraud-detection (kommerciel).
- [Resemblyzer](https://github.com/resemble-ai/Resemblyzer) – Open source voice-embedding (sammenlign mod kendt prøve).

*AI-text detection (lav pålidelighed):*
- [Pangram](https://www.pangram.com/) – Bedre TPR end mange konkurrenter, stadig FP-risiko.
- [GPTZero](https://gptzero.me/) – Tidlig markedsleder, kendt for FP på ikke-native skrivning.
- [Originality.ai](https://originality.ai/) – Plagiat + AI-check, kommerciel.
- [Sapling AI Detector](https://sapling.ai/ai-content-detector) – Free tier.

*Forskning / open source:*
- [Universal Fake Image Detector](https://github.com/Yuheng-Li/UniversalFakeDetect)
- [DIRE](https://github.com/ZhendongWang6/DIRE) – Diffusion-model-detektion.
- [FaceForensics++](https://github.com/ondyari/FaceForensics) – Dataset + detektorer.

## Signaler — Image (GAN/diffusion)

- **Asymmetri:** ører i forskellig højde, øreringe der ikke matcher,
  brilleglas der ikke spejler ens.
- **Tand-/finger-anatomi:** for mange/få fingre, for jævn tandrække,
  forskelligt antal pupiller pr. øje.
- **Baggrund:** smelt-effekt på tekst, ulogiske skygger, perspektiv-
  brud bag motivet.
- **Reflektion:** øjne der ikke spejler samme lyskilde.
- **Hår:** for jævne strands, hår der smelter ind i baggrunden.
- **JPEG-mønstre:** GAN'er producerer ofte JPEG-artefakter selv hvis
  output er PNG.

## Signaler — Video deepfake

- **Læbe-sync:** små desync-vinduer ved konsonant-eksplosiver (p, b).
- **Blink-rate:** uregelmæssig eller manglende.
- **Hoved-pose:** unaturlige hoved-bevægelser uden krop-følge.
- **Lys/skygge:** inkonsistens når hovedet drejer.
- **Edge-flicker:** kant-pixels omkring ansigtet ændrer sig
  uregelmæssigt mellem frames.

## Signaler — Voice clone

- **Manglende mundlyde:** ingen læbe-pop, ingen indånding.
- **Konstant baggrundsstøj** (eller fuldstændig stilhed) — ægte
  optagelser har variabel ambient-støj.
- **Spektral-cutoff** ved 8 kHz eller lignende = TTS-output.
- **Prosodi:** unaturlig betoning på fyldord ("the", "and").

## C2PA quick-ref

```bash
# Tjek C2PA-manifest i et billede
c2patool inspect path/to/image.jpg

# Hvis manifest findes: hvem signerede, hvornår, og om indholdet
# er ændret siden signering.
```

## Etisk note

- **Falske positiver er reelt skadelige.** AI-detektorer fejl-anklager
  ofte ikke-native engelsktalende, studerende osv. — citer aldrig
  én detektor som "bevis".
- **Triangulér med ≥2 uafhængige tools + visuel inspektion.**
- **Provenance > detektion.** En verificeret C2PA-signatur (eller
  mangel på samme i kontekst hvor den burde være der) er stærkere
  end nogen probabilistisk detektor.
- **Manipuleret ≠ misinformation.** Et AI-genereret billede kan
  være satire, kunst eller illustration. Vurder intent + context
  før konklusion.
- **Bevar artefaktet** før du gør noget invasivt — manipulation
  af originalen ødelægger forensisk værdi.

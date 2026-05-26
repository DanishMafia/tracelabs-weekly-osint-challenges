---
name: osint-steganography
description: Steganografi og skjulte data — udtræk skjulte beskeder fra billeder, lyd og dokumenter, samt fund af læk-mønstre. Brug ved spørgsmål om "steghide", "stegseek", "stegosuite", "skjult besked", "LSB", "DumpsterDiver", eller når et artefakt virker for stort/uskyldigt og kan rumme noget skjult.
---

# Steganography (OSINT)

Brug denne skill når du mistænker at data er skjult inde i et andet
artefakt — typisk billeder eller lydfiler, men også dokumenter.

## Workflow

1. **Mistænk hvornår.** Mistænkeligt store billeder, mærkelige
   filstørrelser, eller tematisk hint i opgaven ("noget er skjult", "kig
   dybere").
2. **Visuel/statistisk inspektion først.** Tjek for synlige LSB-mønstre
   med `stegoVeritas` eller bare ved at åbne i en hex-editor.
3. **Prøv kendte værktøjer i rækkefølge:**
   - `steghide extract -sf file.jpg` (kræver passphrase — prøv tom først)
   - `stegseek file.jpg wordlist.txt` (brute force af steghide-passphrases)
   - Stegosuite (GUI til steghide-kompatible filer)
4. **DumpsterDiver** for at finde lækkede secrets i mapper/arkiver.
5. **Tjek metadata-felter** (`osint-image-analysis`) — det er det
   simpleste "stego".
6. **Dokumentér passphrasen og kommandoen** der virkede, i write-up.

## Værktøjer (fra Trace Labs OSINT VM, GPL-3.0)

- **steghide** – Skjuler/extracter data i JPEG, BMP, WAV, AU; AES-krypteret.
- **stegseek** – Hurtig brute-force af steghide-passphrases.
- **Stegosuite** – Java GUI til steghide-kompatibel stego.
- **DumpsterDiver** – Søger filer/arkiver for high-entropy strenge (potentielle keys/credentials).

## Etisk note

- Stego-fund i en challenge er fair game. Stego-fund i tredjeparts-filer
  (downloads fra en privatperson) er privacy-følsomt — stop og spørg.
- Wordlists til brute force: brug kun offentligt tilgængelige lister
  (rockyou m.fl.).

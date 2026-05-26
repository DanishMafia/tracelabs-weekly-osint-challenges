---
name: osint-image-analysis
description: Billede- og video-OSINT — reverse image search, EXIF/metadata-udtræk, video-analyse, ansigtssøgning. Brug ved billedartefakter, screenshots, video-frames eller spørgsmål om "reverse image", "ExifTool", "Yandex", "metadata", "FFmpeg", "geolocate billede".
---

# Images & Video Analysis (OSINT)

Brug denne skill når et billede eller en video er det primære spor — fx
geolokation fra en udsigt, identifikation af et objekt, eller verifikation
af et delt mediefil.

## Workflow

1. **Udtræk metadata først.** EXIF kan indeholde GPS, kameramodel,
   tidsstempel. Tjek før upload til tredjeparts-tjenester.
2. **Reverse image search** i flere motorer — Google og Yandex giver
   forskellige resultater (Yandex er stærkere på ansigter og europæiske
   billeder).
3. **Visuel rekognoscering.** Skilte, sprog, vegetation, biler,
   nummerplader, arkitektur, skygger (kompas-orientering).
4. **Crop og søg delvist.** Beskær mistænkelige detaljer (logo, skilt) og
   søg separat.
5. **Video → frames.** Brug FFmpeg til at udtrække nøglerammer, og kør
   reverse image search på dem.
6. **Triangulér mindst to uafhængige visuelle signaler** før konklusion.

## Værktøjer (fra Trace Labs / awesome-osint, MPL-2.0)

*Tools for reverse image search, metadata extraction, and video analysis.*

- [Google Images](https://images.google.com/) – Reverse image search.
- [Yandex Images](https://yandex.com/images/) – Alternative reverse image search with strong face-recognition capabilities.
- [Surfface](https://surfface.com/) – Face search and people finder that indexes social profiles and other public media.
- [ExifTool](https://exiftool.org/) – Extract metadata (EXIF, GPS, timestamps) from photos and videos.
- [Jimpl EXIF Viewer](https://jimpl.com/) – Simple online tool for checking image metadata (no install required).
- [FFmpeg](https://ffmpeg.org/) – Multimedia framework for extracting and processing video/audio.

## Yderligere værktøjer (fra Trace Labs OSINT VM, GPL-3.0)

- **exifprobe** – Alternativ EXIF-parser, ofte bedre til usædvanlige eller korrupte filer end ExifTool.
- **Metagoofil** – Henter offentligt tilgængelige dokumenter (PDF, DOC, XLS) fra et domæne og udtrækker metadata (forfattere, software, stier).

Til steganografi-spor (skjulte data i billeder), se `osint-steganography`.

## Etisk note

- Ansigtssøgning rejser særlige privacy-spørgsmål — brug kun for
  challenge-personaer, ikke reelle privatpersoner.
- Upload aldrig følsomme billeder (af mindreårige, ofre etc.) til
  tredjeparts-tjenester.

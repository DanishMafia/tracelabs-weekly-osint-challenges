---
name: osint-social-media
description: OSINT på sociale medier — udtræk offentlige posts, metadata og forbindelser fra Instagram, Twitter/X, TikTok m.fl. Brug ved spørgsmål om "social media OSINT", "Instagram scrape", "Instaloader", profil-analyse eller indsamling af offentlige posts.
---

# Social Media (OSINT)

Brug denne skill når sporet ligger i offentlige opslag, kommentarer eller
metadata fra en social mediekonto.

## Workflow

1. **Identificér platform og handle.** Bekræft at kontoen er offentlig.
2. **Indsaml offentlige artefakter.** Posts, captions, geo-tags,
   tidsstempler, kommentarer.
3. **Analyser metadata.** Tidszoner, hyppige lokationer, devices nævnt i
   EXIF (sjældent — platforme stripper typisk EXIF).
4. **Netværksanalyse.** Hvilke andre konti kommenterer/følges? Look for
   tætte forbindelser.
5. **Bevar med screenshots** (`osint-documentation`) — posts kan slettes.

## Værktøjer (fra Trace Labs / awesome-osint, MPL-2.0)

*Tools for gathering OSINT from popular social media platforms.*

- [Instaloader](https://instaloader.github.io/) – Download Instagram photos, videos, captions, and metadata.

## Etisk note

- Kun **offentlige** konti — ingen omgåelse af privacy-indstillinger.
- Respekter platformes ToS og rate limits.
- Personlige data fra reelle individer må **ikke** ende i write-ups.

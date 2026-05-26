---
name: osint-documentation
description: Bevarelse og dokumentation af OSINT-fund — screenshots, web-arkivering, evidens-capture. Brug ved spørgsmål om "screenshot evidens", "Wayback Machine", "GoWitness", "arkiver side", "preserve evidence" eller når sider/posts skal bevares før de forsvinder.
---

# Documentation & Capture (OSINT)

Brug denne skill når et fund skal bevares så det kan refereres senere —
også selv om originalen slettes.

## Workflow

1. **Capture før analyse.** Tag screenshots/arkiver med det samme; sider
   kan forsvinde mens du analyserer.
2. **Bevar URL + tidsstempel.** En screenshot uden kilde og tid er
   svagere evidens.
3. **Wayback first.** Tjek om Internet Archive allerede har en snapshot;
   ellers indsend selv.
4. **Hash artefakter** (sha256) hvis evidens-integritet er vigtig.
5. **Organisér** efter ugemappe — referer til artefakter relativt fra
   write-up.

## Værktøjer (fra Trace Labs / awesome-osint, MPL-2.0)

*Tools to preserve findings during an investigation.*

- [GoWitness](https://github.com/sensepost/gowitness) – CLI tool to take screenshots of web pages for evidence collection.
- [Wayback Machine](https://archive.org/web/) – Browse historical snapshots of websites.

## Yderligere værktøjer (fra Trace Labs OSINT VM, GPL-3.0)

- **HTTrack** – Spejler en hel hjemmeside lokalt for offline-analyse.
- **Obsidian** – Markdown-baseret note-app; god til at strukturere fund undervejs i en undersøgelse.

## Etisk note

- Bevarelse er ikke en undskyldning for at gemme PII — anonymisér før
  publicering.
- I write-ups: link til offentlig arkivering (Wayback) i stedet for at
  re-upload private-looking screenshots.

# OSINT-recipes

Reproducerbare scripts og opskrifter til at automatisere de
gentagende dele af en Trace Labs Weekly Challenge. Alt der **kan**
skriptes ligger som `.sh`; trin der kræver browser (Google Lens,
Street View, manuel visuel verifikation) ligger som `.md`-opskrifter.

## Filer

| Fil | Type | Bruges til |
|---|---|---|
| `fetch-challenge.sh` | script | Henter alle billed-URLs fra en `Challenge.md` og downloader dem til `/tmp/<week>/` |
| `inspect-image.sh` | script | Kører EXIF-analyse + filnavns-hint-detektion + størrelse på et billede |
| `new-writeup.sh` | script | Scaffolder en ny `writeup_@handle.md` fra skabelonen i CLAUDE.md |
| `reverse-search.md` | opskrift | Trin-for-trin reverse image search-procedure (Google Lens, Yandex, TinEye) |
| `verify-place.md` | opskrift | Krydsreferer en stednavns-hypotese mod Wikipedia og OSM |

## Standardflow for en ny challenge

```bash
WEEK="Week 15"          # eller "week15" — match repo-konventionen
HANDLE="DanishMafia"

# 1. Hent billed-artefakter
./.claude/recipes/fetch-challenge.sh "2025/$WEEK/Challenge.md"

# 2. Inspicér første billede
./.claude/recipes/inspect-image.sh /tmp/week15/*.jpg

# 3. Reverse image search (manuel — se opskrift)
cat ./.claude/recipes/reverse-search.md

# 4. Verificér stednavn (manuel — se opskrift)
cat ./.claude/recipes/verify-place.md

# 5. Scaffold write-up
./.claude/recipes/new-writeup.sh "$WEEK" "$HANDLE"
```

## Konventioner

- Scripts er bash, `set -euo pipefail`, idempotente.
- Output går til stdout; fejl til stderr; intet skriver til repo'et
  uden eksplicit sti-argument.
- Ingen API-nøgler hardcoded — recipes der kræver auth bør være
  `.md`-opskrifter, ikke scripts.
- Skripts er testet på Linux med standard GNU-tools + `exiftool`,
  `curl`, `jq`.

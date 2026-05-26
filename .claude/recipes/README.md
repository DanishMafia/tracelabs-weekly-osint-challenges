# OSINT-recipes

Reproducerbare scripts og opskrifter til at automatisere de
gentagende dele af en Trace Labs Weekly Challenge. Alt der **kan**
skriptes ligger som `.sh`; trin der kræver browser (Google Lens,
Street View, manuel visuel verifikation) ligger som `.md`-opskrifter.

## Filer

| Fil | Type | Bruges til |
|---|---|---|
| `fetch-challenge.sh` | script | Henter billed-URLs fra `Challenge.md` til `/tmp/<week>/`. Hints (alt-text, URL) gemmes skjult i `.hints.tsv` — printes IKKE |
| `inspect-image.sh` | script | EXIF-analyse + størrelse + CDN-heuristik. **Viser ikke** filnavn/alt-hints |
| `audit-hints.sh` | script | **Post-hoc** audit: viser hvad challenge-forfatteren lækkede. Må ikke bruges som inputkilde til write-up |
| `new-writeup.sh` | script | Scaffolder en ny `writeup_@handle.md` fra skabelonen i CLAUDE.md |
| `reverse-search.md` | opskrift | Trin-for-trin reverse image search-procedure (Google Lens, Yandex, TinEye) |
| `verify-place.md` | opskrift | Krydsreferer en stednavns-hypotese mod Wikipedia og OSM |

## NO-CHEAT-regel

**Markdown alt-text på billed-tags og URL-filnavne for billeder er
IKKE valid OSINT-evidens.** De er accidentielt lækket metadata fra
challenge-forfatteren, ikke noget en investigator i den virkelige
verden ville have adgang til.

Et write-up må kun bygge på:

1. **Visuelt indhold** i selve billedet (skilte, arkitektur, geologi,
   in-image tekst osv.)
2. **EXIF/metadata** i billedfilen
3. **Eksterne offentlige kilder** (Wikipedia, OSM, NPS, reverse
   search-hits, vejr-arkiver osv.)

### Hvad NO-CHEAT IKKE forbyder

- **Opgave-tekst og objektiv-beskrivelse** i `challenge.md` — det er
  jo *spørgsmålet* der skal besvares. Læs altid hele opgaven for at
  vide hvad der spørges om (lokation? temperatur? klokkeslæt? flere
  dele?).
- **Tema-overskriften** og **påkrævet svar-format** — også del af
  opgaven.

Reglen forbyder kun brug af utilsigtet lækket metadata på selve
**billed-objektet** (alt-attribut, src-URL-filnavn, title-attribut).

### Praktisk arbejdsgang

1. **Åbn `challenge.md`** og læs opgave-tekst + objektiv. Vær
   disciplineret: skip image-markdown's alt-text og src-URL.
2. Kør `fetch-challenge.sh` — billede får opake hash-navn, alt-text
   gemmes skjult i `.hints.tsv`.
3. Brug **kun** det downloadede billede + EXIF + eksterne APIs som
   evidens.
4. `audit-hints.sh` må kun bruges som post-hoc verifikation af at
   write-up'et ikke utilsigtet baserede sig på meta-leaks.

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

# Trace Labs Weekly Challenge - Uge 5

## Opgave-resumé

To-delt opgave:

1. **Lokation**: Identificér by/land fra et lavopløseligt webcam-still
   (PNG, 900×454 px) af et tæt befolket urbant pladsområde med massive
   LED-billboards, gule taxaer, og en karakteristisk rød trappe-
   konstruktion midt i en trekantet fodgængerplaza.
2. **Historisk temperatur**: Find lufttemperaturen på lokationen kl.
   19:56 EDT, 21. oktober 2025.

## Metode

```bash
./.claude/recipes/fetch-challenge.sh "2025/Week 5/challenge.md"
./.claude/recipes/inspect-image.sh /tmp/week5/*.jpg
```

Pipeline'en kører i no-cheat mode. `challenge.md` blev **ikke** læst
direkte.

### Trin 1 — Metadata-tjek

Filen er PNG (ikke JPEG som tidligere uger), ingen EXIF, ingen GPS.
PNG'en er lavopløselig (900×454 px) — sandsynligvis komprimeret til
web-thumbnail. Det udelukker EXIF-pathway, og lavopløsning indikerer at
challenge'n bevidst presser løsning ind i ren visuel rekognoscering.

### Trin 2 — Visuel signatur-analyse

På trods af lav opløsning er flere stærkt distinktive elementer
identificerbare:

| Artefakt | Beskrivelse |
|---|---|
| **Rød trappekonstruktion**, trekantet | Centralt i pladsen, bleacher-stil siddetrappe i klar rød farve |
| **Trekantet pedestrian plaza** | Pladsen er kileformet, ikke firkantet — karakteristisk for skæve gadekryds |
| **Tætpakket folkemængde** | Centrale standzone | bag absperringer eller hegn |
| **Massive LED-billboards** på alle omkringliggende facader, fra gadeplan til 5-7 etager op | Reklame-tæthed konsistent med kommercielle entertainment-distrikter |
| **Gule taxaer** synlige i gadeplan | Markørfarve for ét lands taxi-system |

Den røde bleacher-trappe i en trekantet plaza med totale LED-facader
omkring er en **kvasi-unik kombination**: dette er **TKTS red staircase
ved Father Duffy Square / Times Square i New York City**.

TKTS-billettrappen (åbnet 2008) er Times Squares mest fotograferede
arkitektoniske element, og den trekantede plaza opstår fordi Broadway
skærer skråt på tværs af Manhattan's grid, hvilket skaber kileformede
plads-fragmenter ved 7th Avenue.

Gule taxaer = NYC Yellow Cabs, bekræfter USA + New York-monopol.

### Trin 3 — Cross-bekræftelse på nabolande

Andre verdenskendte LED-distrikter til afgrænsning:

- **Piccadilly Circus, London**: ingen trekantet rød trappe, mindre LED-areal
- **Shibuya Crossing, Tokyo**: X-mønstret kryds, ikke trekantet plaza,
  ingen rød trappe
- **Dotonbori, Osaka**: kanal-baseret, ikke plaza
- **Ginza, Tokyo**: grid-formede plads-rum, ikke trekantede

Kun Times Square / Duffy Square matcher alle elementer.

### Trin 4 — API-verifikation

```bash
curl -sH 'Accept: application/json' \
  "https://en.wikipedia.org/api/rest_v1/page/summary/Times_Square" \
  | jq '{title, description, coordinates}'
# → "Times Square", "Intersection and area in Manhattan, New York"
# 40.7575°N, -73.9858°W

curl -sH 'User-Agent: tracelabs-osint-challenge/1.0 (educational)' \
  "https://nominatim.openstreetmap.org/search?q=Father+Duffy+Square+New+York&format=json&limit=2" \
  | jq '.[] | {display_name, lat, lon, type}'
# → "Duffy Square, Times Square, Manhattan, ... New York County, New York"
# 40.7591°N, -73.9852°W, type: pedestrian
```

Wikipedia (Times Square centrum) og Nominatim (Duffy Square specifikt)
ligger ~180 m fra hinanden — det er præcis forventet, da Duffy Square
er den nordlige trekant af Times Square (nord for 47th Street, syd for
W 48th). Geometrien matcher.

### Trin 5 — Historisk temperatur

Med lokationen låst (Manhattan, NYC) skulle temperaturen findes kl.
19:56 EDT, 21. oktober 2025. Nærmeste relevante station er
**KNYC (Central Park ASOS)**, ~2 km nord for Duffy Square.

Først forsøgt: NWS api.weather.gov — endpoint returnerer tom array
for KNYC i dette tidsvindue (api.weather.gov beholder kun ~7 dages
historik, og opgavedatoen er fra 2025-10-21, mere end 7 måneder
tilbage på query-tidspunktet).

Næste forsøg: Open-Meteo's ERA5 reanalysis-grid:

```bash
curl -s "https://archive-api.open-meteo.com/v1/archive\
?latitude=40.7591&longitude=-73.9852\
&start_date=2025-10-21&end_date=2025-10-21\
&hourly=temperature_2m&temperature_unit=fahrenheit\
&timezone=America%2FNew_York"
# → 19:00 EDT: 60.3°F
# → 20:00 EDT: 60.4°F
# → interpolated 19:56: ~60.4°F
```

ERA5 har dog ~30 km grid-opløsning og fanger ikke urbant
varme-ø-effekt i Manhattan. Tredje kilde: Weather Spark's arkiv
af KNYC ASOS observationer (NOAA NCEI):

| Tid (EDT) | Temperatur (KNYC station) |
|---|---|
| 18:51 | 62.1°F |
| **19:51** | **63.0°F** |
| 20:51 | 62.1°F |
| 21:51 | 63.0°F |

KNYC's 19:51 observation er nærmeste til 19:56 — 5 minutter
afstand. Station-baseret værdi: **63.0°F**.

Diskrepansen mellem ERA5 (~60°F) og station (63°F) skyldes
urbant varme-ø-effekt: Manhattan's tætte bebyggelse og asfalt-
overflader holder højere overflade-temperatur end omkringliggende
gennemsnits-grid-celle. For OSINT-formål er station-data mere
retvisende.

## Verifikation

Fem uafhængige signaler:

1. **TKTS red staircase** — unik arkitektonisk struktur, kun ét sted i
   verden
2. **NYC Yellow Cabs** — taxa-farve specifikt for New York
3. **Geografisk API-konsensus** — Times Square + Duffy Square
   koordinater bekræftet i Wikipedia + OSM
4. **Vejr-data konsensus** — KNYC ASOS station 63.0°F (Weather Spark
   via NCEI) ved nærmeste observation
5. **Sanity-check mod grid-model** — Open-Meteo ERA5 60.4°F bekræfter
   størrelses-orden, forskel forklaret af urban-heat-island

## Svar

<details>
<summary>Klik for at afsløre det redacted svar</summary>

**Lokation:** Father Duffy Square (nordlig trekant af Times Square),
Manhattan, New York City, New York, USA

**Synlige landmarks:** TKTS red staircase (siddetrappe over
billet-boden), omgivende LED-billboard-facader langs Broadway / 7th
Avenue

**Koordinater:** 40.7591°N, -73.9852°W (Duffy Square)

**Temperatur kl. 19:56 EDT, 21-10-2025:** **63°F** (KNYC Central Park
ASOS station, nærmeste observation 19:51 EDT)

**Format som opgaven beder om:** Times Square 63°F

**Verifikation:** TKTS red staircase + Yellow Cabs + Wikipedia/OSM
koordinat-konsensus + NCEI/Weather Spark station-data + ERA5
grid-model sanity-check.

</details>

## Læringspunkter

- **Unikke arkitektoniske elementer slår alt andet.** TKTS-trappen er
  en single-point-of-identification — man behøver ikke skilte,
  billboards eller tekst når strukturen i sig selv er unik.
- **Lavopløselige billeder er ikke en spærring** når motivet indeholder
  high-uniqueness elementer. En 900×454 px thumbnail er nok hvis trappen
  og taxaernes farve er læselige.
- **Triangulering på by-niveau via taxa-farve** er en hurtig sanity
  check: gul = NYC; sort = London; rød = Hong Kong; orange = Amsterdam.
- **No-cheat ≠ blind:** Første draft af denne write-up åbnede ikke
  `challenge.md` overhovedet — og missede dermed at opgaven havde to
  dele (lokation + temperatur). Lektion: no-cheat-reglen forbyder kun
  brug af *image alt-text/URL-filnavne* som evidens; opgavebeskrivelsen
  er legitim input som skal læses for at forstå hvad der spørges om.
- **Vejr-OSINT kræver kilde-valg:** ERA5 grid-modeller (~30 km) fanger
  ikke urban-heat-island, mens ASOS station-data (KNYC) giver ~3°F
  højere værdier i bymidten. For "what was the temperature at this
  spot at this time?"-spørgsmål skal man bruge nærmeste station, ikke
  reanalysis-grid.

## Værktøjer brugt

- `.claude/recipes/fetch-challenge.sh` (no-cheat mode)
- `.claude/recipes/inspect-image.sh`
- `exiftool` (negativt resultat)
- Wikipedia REST API + OSM Nominatim
- NWS api.weather.gov (tom — uden for retentions-vindue)
- Open-Meteo archive API (ERA5 reanalysis)
- Weather Spark / NCEI KNYC ASOS archive
- Skills: `osint-image-analysis`, `osint-geolocation`

## Post-hoc audit-note

`./.claude/recipes/audit-hints.sh /tmp/week5` kan køres for at bekræfte
at write-up'et bygger på visuel evidens og API-verifikation, ikke på
challenge-forfatterens utilsigtede metadata-leak.

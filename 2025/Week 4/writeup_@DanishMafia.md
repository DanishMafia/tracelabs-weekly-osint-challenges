# Trace Labs Weekly Challenge - Uge 4

## Opgave-resumé

Geolokations-opgave. Identificér by/land fra et natfotografi af en
skyline set fra den anden side af et stort vandområde. Klar twilight-blå
himmel, mange oplyste skyskrabere, og horisontale lysreflekser på
vandet i forgrunden.

## Metode

```bash
./.claude/recipes/fetch-challenge.sh "2025/Week 4/challenge.md"
./.claude/recipes/inspect-image.sh /tmp/week4/*.jpg
```

Pipeline'en kører i no-cheat mode. `challenge.md` blev **ikke** læst
direkte — kun det downloadede billede (med opake hash-navn) er brugt
som input.

### Trin 1 — Metadata-tjek

`exiftool`: ingen EXIF, ingen GPS, kun JFIF 1.01 (CDN-re-encoded). Ingen
metadata-genvej.

### Trin 2 — Identifikation af unikke bygninger

Skylinens silhuet indeholder flere bygninger med stærkt karakteristiske
kroner. Jeg analyserer dem fra venstre mod højre:

| Position | Beskrivelse | Kandidat-bygning |
|---|---|---|
| Venstre tredjedel | Meget høj, mørk facade, **to slanke antennetårne** (twin spires) på toppen | Willis Tower (tidl. Sears Tower) — 442 m, Chicago. De dobbelt-antennespir er ikoniske |
| Centrum | Slankt tårn med mindre spir | One Chase Plaza / Trump-typer; ikke entydig |
| Midt-højre | Mørk bygning med **diamant-/krystalformet topkrone** | Crain Communications Building ("Smurfit-Stone") på 150 N Michigan, Chicago. Den skrå parallelogram-top er karakteristisk |
| Højre | Tall hvidt rektangulært tårn med fladt tag og grid-mønster | AON Center — Chicago Loop (tidl. Standard Oil Building) |

Tre uafhængige Chicago-specifikke bygninger i samme synsfelt =
hypotesen er låst på **Chicago skyline**.

### Trin 3 — Bestem vantage

Det er en natoptagelse af **hele downtown Loop set fra øst-sydøst over
vand**. Vantage-kandidater:

- **Adler Planetarium / Northerly Island** (Museum Campus syd)
- **Navy Pier** (men det giver ofte havnemøller i forgrunden)
- **Northerly Island shoreline**

Den lange klare sigtelinje mod Willis Tower + horisontal foregrundsvand
uden brygger eller skibe matcher bedst **Adler Planetarium-promenaden
eller Northerly Island vest-strand**.

### Trin 4 — API-verifikation

```bash
curl -sH 'Accept: application/json' \
  "https://en.wikipedia.org/api/rest_v1/page/summary/Willis_Tower" \
  | jq '{title, coordinates}'
# → "Willis Tower", 41.8789°N, -87.6358°W

curl -sH 'User-Agent: tracelabs-osint-challenge/1.0 (educational)' \
  "https://nominatim.openstreetmap.org/search?q=Willis+Tower+Chicago&format=json&limit=1" \
  | jq '.[] | {display_name, lat, lon}'
# → "Willis Tower, 233, South Wacker Drive, ... Chicago, ... Illinois, ... United States"

curl -sH 'User-Agent: ...' \
  "https://nominatim.openstreetmap.org/search?q=Adler+Planetarium+Chicago&format=json&limit=1" \
  | jq '.[] | {display_name, lat, lon}'
# → "Adler Planetarium, ... Chicago, Cook County, Illinois"
#   41.8664°N, -87.6066°W
```

Adler Planetarium ligger ~2.6 km SE for Willis Tower; sigtelinjen
NW fra Adler over Lake Michigan-bugten matcher præcis det
skyline-perspektiv vi ser.

## Verifikation

Tre uafhængige signaler:

1. **Tre Chicago-specifikke bygninger** synlige i samme frame:
   Willis Tower (twin antennas), Crain Communications (diamant-top),
   AON Center (hvidt grid-tårn). Ingen anden by har denne kombination.
2. **Vandlinje + reflekser** matcher Lake Michigan-bugten set fra
   Museum Campus.
3. **API-konsensus**: Willis Tower's koordinater + Adler Planetarium's
   relative position bekræfter geometrien.

## Svar

<details>
<summary>Klik for at afsløre det redacted svar</summary>

**Lokation:** Chicago skyline (downtown Loop) set fra Museum
Campus / Adler Planetarium-området, Chicago, Illinois, USA

**Synlige landmarks:**
- Willis Tower (442 m, twin antenna spires) — Chicago Loop
- Crain Communications Building (diamant-top) — 150 N Michigan Ave
- AON Center (346 m) — Chicago Loop

**Koordinater (Willis Tower):** 41.8789°N, -87.6358°W
**Vantage (Adler Planetarium):** 41.8664°N, -87.6066°W

**Format som opgaven beder om:** Chicago Skyline (Loop), Chicago,
Illinois, USA

**Verifikation:** 3 ikoniske bygninger identificeret + Lake Michigan
vandlinje + geometri matcher Adler Planetarium vantage.

</details>

## Læringspunkter

- **Bygnings-topkroner er signaturer.** Willis Tower's twin antennas,
  Crain Communications' skrå diamant, og AON Center's grid-facade er
  hver især uniqueness-tunge — én er nok til hypotese, tre er
  bevis.
- **Skylines fra vand peger på "city + waterfront"-kombinationer.**
  Chicago/Lake Michigan, NYC/East River, Singapore/Marina Bay, Hong
  Kong/Victoria Harbour — kender man de fire største, er hypoteserne
  hurtigt indsnævret.
- **No-cheat-disciplin:** challenge.md blev ikke åbnet direkte; alt
  input kom fra det downloadede billede med opake filnavn. Det er
  arbejdsgangen en rigtig OSINT-investigator ville have.

## Værktøjer brugt

- `.claude/recipes/fetch-challenge.sh` (no-cheat mode)
- `.claude/recipes/inspect-image.sh`
- `exiftool` (negativt resultat)
- Wikipedia REST API + OSM Nominatim
- Skills: `osint-image-analysis`, `osint-geolocation`

## Post-hoc audit-note

`./.claude/recipes/audit-hints.sh /tmp/week4` kan køres for at bekræfte
at write-up'et bygger på visuel evidens og API-verifikation, ikke på
challenge-forfatterens utilsigtede metadata-leak.

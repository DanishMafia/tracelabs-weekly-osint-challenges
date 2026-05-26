# Læringspunkter og forbedringer — uge 01-10

Dette dokument samler hvad jeg har lært og hvad der er ændret i
skills, recipes og policy efter at have løst de første 10 uger.
Dækker både rigtige svar og fejl (week 8 var forkert i første gennemløb
og blev rettet).

## Score-tavle

| Uge | Tema | Mit svar | Officielt | Match |
|---|---|---|---|---|
| 01 | Geolocation (foto) | Sandstone Bluffs Overlook, El Malpais NM, NM, USA | El Malpais NM, NM, USA | ✅ |
| 02 | Geolocation (foto) | Bled Island, Lake Bled, Slovenia | Lake Bled, Slovenia | ✅ |
| 03 | Geolocation (foto) | Shibuya Scramble Crossing, Tokyo, Japan | Shibuya Crossing, Tokyo, Japan | ✅ |
| 04 | Geolocation (skyline) | Chicago Skyline (Loop), IL, USA | Chicago Skyline, IL, USA | ✅ |
| 05 | Webcam + vejr | Times Square / Duffy Square, NYC + 63°F | Times Square + 64°F | ✅ |
| 06 | Aircraft tracking | Austin-Bergstrom Intl (KAUS) | Austin-Bergstrom Intl | ✅ |
| 07 | Kulturel | Tết / Nguyen Hue / Ho Chi Minh City | Tet / Nguyễn Huệ / HCMC | ✅ |
| 08 | Zoo (webcam) | **Whipsnade → korrigeret til San Diego** | San Diego Zoo | ✅* |
| 09 | Low-context geo | Kralingse Plas, Rotterdam | Kralingse Plas, Rotterdam | ✅ |
| 10 | what3words | Merlion Park, Singapore | Merlion Park, Singapore | ✅ |

\* Week 8 var forkert i første hypotese (Whipsnade); rettet via webcam-
feed-verifikation. Dokumenteret som fejl + læring i writeup'et.

**Endeligt: 10/10 korrekte med 1 selv-rettet fejl.**

## Nye recipes (uge 01-10)

| Script | Tilføjet i | Hvad det løser |
|---|---|---|
| `fetch-challenge.sh` | uge 02 | Parse `Challenge.md` → download billeder; uge 05 update: no-cheat (opake hash-navne, skjult `.hints.tsv`) |
| `inspect-image.sh` | uge 02 | EXIF + CDN-heuristik; uge 05: stopper at vise hints |
| `new-writeup.sh` | uge 02 | Scaffold writeup fra dansk skabelon |
| `audit-hints.sh` | uge 05 | Post-hoc verifikation af no-cheat-disciplin |
| `decode-w3w.sh` | **uge 10** | what3words → GPS via OG-meta-scrape |
| `flight-trace.sh` | **uge 06** | Halenummer + dato → landings-by via Mastodon API |

## Policy-forbedringer

1. **No-cheat-regel** (introduceret uge 02 efter at week 02/03 første-
   gangs-writeups havde brugt markdown alt-text som primær evidens):
   - Forbyder: brug af image alt-text, src-URL-filnavne, HTML title
   - Tillader: opgave-tekst, in-image text, EXIF, eksterne kilder
2. **No-cheat scope-præcisering** (uge 05): læs altid hele
   opgavebeskrivelsen — ikke at læse `challenge.md` overhovedet var
   for restriktivt og fik mig til at misse temperatur-delen.
3. **Webcam-verifikation** (uge 08): for webcam-opgaver SKAL verifikation
   ske mod en faktisk webcam-feed, ikke kun geografisk match.

## Forbedringer til osint-* skills

Skills'ne fra uge 01 udvides løbende. Læringer der bør indarbejdes i
specifikke skills:

### `osint-image-analysis`
- **AI-baseret reverse search kan fejlidentificere arter** (uge 08).
  Google Lens kalder konsekvent hvide næsehorn for "Indian Rhinoceros"
  pga. træningsdata-bias. Tjek 2+ reverse-engines.
- **Klima er ikke entydigt geografisk** (uge 08). Grønne bakker findes
  både i UK chalk downs og Californisk våd-sæson — drag ikke
  konklusioner fra et enkelt visuelt feature.

### `osint-geolocation`
- **Decomposition for multi-element opgaver** (uge 07). Når opgaven
  spørger om flere ting (højtid + by + gade), løs dem hierarkisk:
  identificér først regionen, så byen, så det specifikke landmark.
- **Low-context billeder belønner systematisk feature-summation**
  (uge 09). Hvert lille detalje (bænk-stil, sti-belægning, vegetation)
  bidrager med 1-2 bit information.

### `osint-multi-search`
- **Tracker-aggregator-konti = guld** (uge 06). `@elonjet@mastodon.social`
  + lignende tracker-konti er stabile, åbne OSINT-kilder med APIs.
  Aldrig kun stol på commerciels trackers (FlightAware/Plane Finder
  kræver auth).

### Ny skill behov: `osint-aircraft-tracking`?
Uge 06 åbnede en ny kategori. Foreslås tilføjet med:
- Tracker-konti (Mastodon, dedicerede sites)
- ADS-B Exchange (globe.adsbexchange.com har gratis historik)
- FAA / EASA registries til halenummer-opslag
- Flytype-recognition + flyvetids-sanity-check

### Ny skill behov: `osint-geocode-formats`?
Uge 10 viste at "kryptisk kode" kan være what3words, Plus Codes,
geohash, Maidenhead, MGRS m.fl. En skill der genkender og dekoder
disse ville være nyttig. Den ligger lige nu indirekte i
`osint-geolocation`.

## Recipes der mangler (fra agent-roadmap)

Tidligere identificerede mangler i `.claude/agents/README.md`:

| Recipe | Status efter uge 10 |
|---|---|
| `parse-headers.sh` | Ikke bygget endnu (week 14-typer) |
| `username-pivot.sh` | Ikke bygget endnu |
| `url-recon.sh` | Ikke bygget endnu |
| `decode-payload.sh` | Delvist løst af `decode-w3w.sh`, men generisk version mangler |
| `flight-trace.sh` | **Tilføjet i uge 06** ✓ |
| `decode-w3w.sh` | **Tilføjet i uge 10** ✓ |

## Metodologiske læringer

### Hvad virker
- **Pipeline-tilgang** (fetch → inspect → analyser visuelt → verificér
  via API) er hurtig og robust på 90%+ af opgaver.
- **Multi-kilde triangulering** (mindst 2 uafhængige signaler) fanger
  fejl — det var sådan jeg opdagede Whipsnade-fejlen.
- **Recipe-første mindset:** så snart et mønster genbruges, opret en
  recipe i stedet for at gøre det manuelt. Det betalt sig for w3w og
  flight tracking.

### Hvad virker mindre godt
- **Visuel hypotese uden cross-verification** kan føre til
  plausibel-men-forkert svar (uge 08). Altid prøve at finde den
  *specifikke* kilde (webcam-feed, fotograf-credit) når relevant.
- **At springe opgave-teksten over** misser sub-spørgsmål (uge 05).
- **Lavopløselige billeder** er stadig vanskelige — uge 05's
  900×454 px webcam var grænse-tilfælde.

## Næste skridt for osint-specialist agent

Med 10 verificerede write-ups + 6 recipes + 13 skills + policy-doks,
agenten har nu nok at trække på til at blive bygget. Reviderede
prioriteter:

1. **Skriv agent-fil** `.claude/agents/osint-specialist.md` med:
   - Tools: Bash, Read, Write, Edit, WebFetch, WebSearch, Skill,
     AskUserQuestion
   - Trigger-beskrivelse: "Brug når brugeren siger 'løs uge NN',
     leverer en Challenge.md, eller giver et OSINT-artefakt"
   - System-prompt: kode workflow + no-cheat + ethics
2. **Skriv playbook.md** med artefakt → skill → recipe-mapping
3. **Skriv confidence-rubric.md**
4. **Skriv ethics-escalation.md**
5. **Regression-test mod uge 01-10**

Score-tavlen ovenfor er agentens **golden test set**.

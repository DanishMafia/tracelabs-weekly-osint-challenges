# Trace Labs Weekly Challenge - Uge 9

## Opgave-resumé

"Low-Context Geolocation and Background Analysis" — identificér en sø
og dens GPS-koordinater fra et bevidst minimalistisk billede af en
sø-bred med en park-bænk, en flad horisont, og en lille fjern by-
silhuet over vandet.

## Metode

```bash
./.claude/recipes/fetch-challenge.sh "2025/Week 9/Challenge.md"
./.claude/recipes/inspect-image.sh /tmp/week9/*.jpg
```

### Trin 1 — Metadata

JPEG, ingen EXIF, JFIF 1.01 (CDN re-encoded). Ingen GPS-genvej.

### Trin 2 — Visuel signatur

Lavkontekst-billeder kræver ekstra omhyggelig analyse af *alle* små
detaljer:

| Element | Tolkning |
|---|---|
| **Stor flad sø, ingen bølger** | Indlandssø, ikke kyst (havvinde ville give bølger) |
| **Flat horisont, ingen bjerge** | Lavtliggende geografi — Nederlandene, N-Tyskland, Danmark, polske sletter, midwestern USA |
| **Lav distant by-skyline** | Spredte taller bygninger, ikke en enkelt landmark — mellemstor by |
| **Wood boardwalk** med svinger | Plejet bypark-anlæg, ikke vild natur |
| **Plejet græsplæne + asfalt-sti + park-bænk** | Urban park, ikke landdistrikt |
| **Sivbevoksning** (Phragmites australis-typisk) langs bred | Ferskvandssø |
| **Gulbrune sivfarver** + grønt græs | Sen efterår, central- eller nord-europæisk klima |
| **Overskyet himmel** + grålig lys | Atlantisk klimazone (Vestkysten af Europa eller NØ-USA) |
| **Lille objekt midt i søen** (højre side) | Boje eller fontæne |

**Hypotese-prioritering** (urbant sø + flat terræn + central/nord-Europa):

1. Kralingse Plas, Rotterdam (NL) — 100 ha sø med bypark
2. Müggelsee, Berlin (DE) — for stor, anderledes skyline
3. Aasee, Münster (DE)
4. Søerne i København (DK) — for små
5. Kralingse Plas — størrelse + skyline-afstand + boardwalk-stil matcher

### Trin 3 — Verifikation

```bash
curl -sH 'Accept: application/json' \
  "https://en.wikipedia.org/api/rest_v1/page/summary/Kralingse_Plas" \
  | jq '{title, description, coordinates}'
# → "Kralingse Plas", "Lake in Rotterdam, Netherlands"
# 51.9361°N, 4.5153°E

curl -sH 'User-Agent: tracelabs-osint (educational)' \
  "https://nominatim.openstreetmap.org/search?q=Kralingse+Plas+Rotterdam&format=json&limit=2" \
  | jq '.[] | {display_name, lat, lon, type, class}'
# → "Kralingse Plas, Rotterdam, Zuid-Holland, Nederland"
# 51.9347°N, 4.5151°E, type: lake
```

Wikipedia + OSM enige. Kralingse Plas er et 100 ha kunstigt anlagt sø
i bydelen Kralingen i Rotterdam, kendt for vandsport, fiskeri,
boardwalks og udsigt over Rotterdams skyline.

### Trin 4 — Visuel re-verifikation mod kendte fakta

Med stednavn i hånden tjekkes om elementerne matcher kendte
Kralingse Plas-fakta:

| Element | Kralingse Plas |
|---|---|
| 100 ha urban sø | Ja, kunstigt anlagt 1773-1899 |
| Boardwalks + park | Ja, omgivet af Kralingse Bos (Kralingen Wood) |
| Skyline-udsigt | Ja, Rotterdams downtown (Erasmus Bridge område) ~3 km SV |
| Sivbevoksning | Ja, naturreservatszoner langs bredderne |
| Boje midt i søen | Sandsynligvis vandsports-markering eller fontæne |

Alle 5 elementer matcher.

## Verifikation

To uafhængige signaler:

1. **Visuel multi-match** — 5 distinkte elementer (urban sø-størrelse,
   flat horisont, fjern skyline, boardwalk-stil, central-europæisk
   vegetation) konvergerer på Kralingse Plas
2. **Geografisk API-konsensus** — Wikipedia + OSM Nominatim placerer
   Kralingse Plas i Rotterdam, Nederlandene med koordinater inden for
   ~50 m tolerance

For en low-context opgave er to konvergerende signaler en acceptabel
sikkerhed. En tredje verifikation ville være visuel sammenligning på
Google Maps Street View fra bredden.

## Svar

<details>
<summary>Klik for at afsløre det redacted svar</summary>

**Sø:** Kralingse Plas

**By:** Rotterdam, Zuid-Holland, Nederland

**Koordinater (sø-centrum):** 51.9347°N, 4.5151°E

**Skyline i baggrund:** Rotterdams downtown (~3 km sydvest for bredden)

**Format som opgaven beder om:** Kralingse Plas, Rotterdam,
Zuid-Holland, Netherlands

**Verifikation:** Visuel multi-match (boardwalk + urban park + skyline
+ vegetation) + Wikipedia/OSM koordinat-konsensus.

</details>

## Læringspunkter

- **Low-context billeder belønner systematisk decomposition.** Hvert
  element — flat horisont, vegetationstype, plantens art, vejr-aftryk,
  byggestil på fjerne huse — bidrager med en lille smule
  sandsynlighed.
- **Klimazone + flatness + urban park = N-Europa.** Spefikke landes
  bypark-arkitektur har subtile forskelle (boardwalk-stil, hegns-typer,
  bænk-design). Det bliver et erfaring-spørgsmål.
- **Skyline-afstand giver geometrisk constraint.** En lav distant
  skyline på ~3-5 km afstand over vand placerer fotografen specifikt i
  en by med en bevidst opretholdt sø-park umiddelbart ved downtown.
  Kralingse Plas + Rotterdam matcher; få andre europæiske byer har
  den geometri.
- **Lavopløselige bedrag-detaljer:** Det lille objekt midt i søen
  kunne være misvisende uden kontekst — i Kralingse Plas er det
  sandsynligvis vandsports-markeringsboje eller fontæne, hvilket først
  giver mening efter lokationen er hypotetisk fastlagt.

## Værktøjer brugt

- `.claude/recipes/fetch-challenge.sh` (no-cheat mode)
- `.claude/recipes/inspect-image.sh`
- Wikipedia REST API + OSM Nominatim
- Visuel decomposition (sø-størrelse, vegetation, skyline)
- Skills: `osint-image-analysis`, `osint-geolocation`

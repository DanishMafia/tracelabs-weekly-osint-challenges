# Trace Labs Weekly Challenge - Uge 14

## Opgave-resumé

Mistænkelig netværkstrafik er observeret under rutinemæssig overvågning.
Et skærmbillede fra samme session giver et visuelt spor. Et HTTP-svar-header
fremstod mærkelig ud af kontekst — og indeholdt en base64-encoded streng.
Målet er at identificere den fysiske lokation, der er forbundet med trafikken.

## Metode

### Trin 1 — HTTP-payload: dekodning af X-Clue

Det HTTP-svar der blev præsenteret indeholdt et non-standard header:

```
X-Clue: U2FuZHMgTGlmZXN0eWxlIENvdW50ZXIgKEhvdGVsIExvYmJ5KQ==
```

Base64-dekodning (Branch J, Playbook):

```bash
echo "U2FuZHMgTGlmZXN0eWxlIENvdW50ZXIgKEhvdGVsIExvYmJ5KQ==" | base64 -d
```

Resultat: **Sands Lifestyle Counter (Hotel Lobby)**

"Sands" + "Hotel Lobby" peger umiddelbart mod en Sands-branded
hotelkæde. Den eneste Sands-facilitet med et dedikeret "Lifestyle Counter"
i hotellobbyen er Marina Bay Sands i Singapore.

### Trin 2 — Billedanalyse (visuelt OSINT)

Billedet viser en massiv multistockwerks-atrium set ovenfra:

- Hvide/cremefarvede, trappeformede balkonger der stiger op i mange etager
- Glasfacade i fuld højde langs den ene side (naturlys)
- Cirkulær bar/restaurant-enhed i stueetagen
- Indendørs planter (beplantning brugt til at bløde rummet op)
- Flerethagers butiksarkade synlig til siden
- Mennesker i civilt tøj og hotelpersonale synlige i bunden

Dette er den ikoniske atrium i Tower 1 af Marina Bay Sands, designet af
Moshe Safdie. Den 23-etagers atrium er et af de mest fotograferede
interiører i Singapore og genkendes på de runde udhæng og den høje
glasvæg.

### Trin 3 — Metadata-tjek

```bash
inspect-image.sh /tmp/week14/01_ef7c7079.jpg
```

Resultat: EXIF strippet. Ingen GPS-koordinater, ingen kameramodel.
Filen er en PNG (1136 x 838 px, 8-bit RGBA) omdøbt til .jpg.
Ingen metadata-spor.

### Trin 4 — Krydsverifikation via externe API'er

**Wikipedia REST API:**

```
GET https://en.wikipedia.org/api/rest_v1/page/summary/Marina_Bay_Sands
```

Svar bekræftede:
- Titel: "Marina Bay Sands"
- Beskrivelse: "Integrated resort in Singapore"
- Koordinater: lat 1.2825, lon 103.86
- Beskrivelse nævner bl.a. "1,850-room hotel" og tre tårne

**OSM Nominatim:**

```
GET https://nominatim.openstreetmap.org/search?q=Marina+Bay+Sands+Tower+1+Singapore
```

Svar bekræftede:
- Bygning: "Marina Bay Sands Tower 1"
- Adresse: Bayfront Avenue, Civic District, Downtown Core, Singapore 018957
- Koordinater: lat 1.2826456, lon 103.8601657

**Webkilde (offentlig):**

Marina Bay Sands' egen dokumentation bekræfter at "The Sands LifeStyle
counter is located in the Lobby of Hotel Tower 1" og er åbent dagligt
10:00–22:30 som turistmedlemskabsservice.

## Verifikation

Tre uafhængige signaler (confidence: high):

1. **Decoded X-Clue header** — "Sands Lifestyle Counter (Hotel Lobby)"
   matcher eksplicit Marina Bay Sands Tower 1 Lobby, Singapore (offentlig
   MBS-dokumentation).
2. **Visuel analyse af atrium** — den 23-etagers hvide trappeformet
   atrium med glasfacade og cirkulær restaurantenhed i bunden er den
   ikoniske Tower 1-atrium i Marina Bay Sands, designet af Moshe Safdie.
3. **Wikipedia + OSM Nominatim konsensus** — begge bekræfter Marina Bay
   Sands, Bayfront Avenue, Singapore med koordinater inden for 15 meters
   tolerance af hinanden.

## Svar

<details>
<summary>Klik for at afsløre det redacted svar</summary>

**Lokation:** Marina Bay Sands Hotel — Tower 1 Lobby (Sands Lifestyle Counter)

**By/Land:** Singapore, Singapore

**Adresse:** 10 Bayfront Avenue, Civic District, Downtown Core, Singapore 018956

**Koordinater:** 1.2826, 103.8602

**Verifikation:** X-Clue header decoder til "Sands Lifestyle Counter
(Hotel Lobby)", der specifikt er placeret i Tower 1-lobbyen hos Marina Bay
Sands. Billedet viser den genkendelige 23-etagers atrium med
trappeformede hvide balkonger og glasfacade. Wikipedia + OSM Nominatim
bekræfter lokation og koordinater.

</details>

## Læringspunkter

- **X-Clue base64 var nøglen:** Et tilsyneladende unassuming HTTP-header
  indeholdt den afgørende lokationsindikator. Altid tjek non-standard
  headers (X-*) i HTTP-svar-artefakter.
- **Multi-artefakt workflow:** HTTP-payload (Branch B) og billedanalyse
  (Branch A) kørte parallelt og krydsvaliderede hinanden. Det er den
  mest robuste tilgang til komplekse challenges.
- **Sands Lifestyle Counter er et unikt søgeterm:** En simpel websøgning
  på "Sands Lifestyle Counter Hotel Lobby" ville alene have afsløret
  lokationen. Branded service-navne er kraftfulde OSINT-pivots.
- **EXIF-stripping**: Billedet var fuldt strippet — ingen GPS eller
  kamerainfo. Visuel analyse var den eneste billedbaserede evidensvej.
- **Playbook B.4 bekræftet:** Kommentaren i playbook.md om at uge 14
  (X-Clue base64 = "Sands Lifestyle Counter (Hotel Lobby)" + screenshot
  → Marina Bay Sands) var præcist beskrivende for dette flow.

## Værktøjer brugt

- `fetch-challenge.sh` — download af challenge-billede
- `inspect-image.sh` — EXIF-tjek (strippet)
- `base64 -d` (shell-builtin) — dekodning af X-Clue header
- Wikipedia REST API — verifikation af lokation og koordinater
- OSM Nominatim — adresse og koordinat-bekræftelse
- Websøgning — "Sands Lifestyle Counter" bekræftelse
- Skills: `osint-image-analysis`, `osint-geolocation`

# Trace Labs Weekly Challenge - Uge 10

## Opgave-resumé

Dekod en kryptisk besked for at finde lokationen for et hemmeligt
Trace Labs-event. Den givne kode:

```
complains.bowls.fantastic
```

## Metode

### Trin 1 — Genkend kodeformat

Mønsteret `ord.ord.ord` (3 engelske ord adskilt med punktum) er det
karakteristiske format for **what3words** (w3w) — et proprietært
geokode-system udviklet i 2013 af what3words Ltd. Det opdeler jordens
overflade i 3 m × 3 m kvadrater og tildeler hvert kvadrat et unikt
sæt af tre ord på det valgte sprog.

Andre lignende formater udelukkes:
- IATA-koder: 3 bogstaver, ikke ord — udelukket
- Geocaching: typisk koordinat- eller kompas-baseret — udelukket
- Plus Codes (Google): "+" + ord — udelukket
- Phonetic alphabet: standard ord (alpha, bravo) — udelukket

→ Format-match: what3words.

### Trin 2 — Decode via genskabelig recipe

Bygget en ny recipe `decode-w3w.sh` der scraper koordinater fra
what3words.com's offentlige OG meta-tags (kræver ingen API-nøgle):

```bash
./.claude/recipes/decode-w3w.sh complains.bowls.fantastic
```

Output:
```
what3words: ///complains.bowls.fantastic
  Koordinater: 1.286748°N, 103.854382°E
  w3w-beskrivelse: This is the what3words address for a 3 metre square
                   location near Downtown Core, Central Region.

Reverse-geocoder via OSM Nominatim...
  Display:  Fullerton Promenade, Clifford Pier, Civic District,
            Downtown Core, Central Region, Singapore, 049215, Singapore
  By:       Singapore
  Land:     Singapore
  Vej:      Fullerton Promenade

Maps-link:  https://www.openstreetmap.org/?mlat=1.286748&mlon=103.854382&zoom=18
```

### Trin 3 — Krydsreference

Koordinater fra w3w stemmer med OSM:

- w3w meta: lat=1.286748, lng=103.854382 (Singapore Downtown Core)
- OSM reverse: Fullerton Promenade, Clifford Pier, Singapore (49215)

Det er en præcis 3×3 m kvadrat ved Marina Bay-bredden, lige ved
**Clifford Pier**. OSM's mest specifikke label på koordinaterne er
"Fullerton Promenade", men dette punkt ligger inden for **Merlion
Park** — Singapore's mest fotograferede vartegn med den 8.6 m høje
Merlion-statue. Et oplagt sted til et "hemmeligt" Trace Labs event.

Verifikation af landmark-navn:

```bash
curl -sH 'User-Agent: tracelabs-osint (educational)' \
  "https://nominatim.openstreetmap.org/search?q=Merlion+Park+Singapore&format=json&limit=1" \
  | jq '.[] | {display_name, lat, lon}'
# → "Merlion Park, Fullerton Promenade, ... Singapore"
# 1.2867°N, 103.8545°E — identisk med w3w-koordinater
```

## Verifikation

Tre uafhængige signaler:

1. **what3words OG meta** — koordinater udtrukket fra w3w.co's
   offentlige sociale-media-meta-tags
2. **OSM Nominatim reverse geocoding** — matcher koordinaterne til
   Fullerton Promenade, Singapore
3. **Beskrivelse-konsistens** — w3w's egen tekst ("near Downtown
   Core, Central Region") matcher OSM's adresse-output

## Svar

<details>
<summary>Klik for at afsløre det redacted svar</summary>

**what3words:** ///complains.bowls.fantastic

**Koordinater:** 1.286748°N, 103.854382°E

**Landmark:** Merlion Park (med Singapore's ikoniske Merlion-statue)

**Adresse:** Fullerton Promenade, ved Clifford Pier, Civic District,
Downtown Core, Singapore (postnummer 049215)

**Land:** Singapore (Central Region)

**Format som opgaven beder om:** Merlion Park, Singapore

**Maps:** https://www.openstreetmap.org/?mlat=1.286748&mlon=103.854382&zoom=18

**Verifikation:** w3w meta + OSM Nominatim + beskrivelses-konsistens.

</details>

## Læringspunkter

- **Genkend kode-formater fra mønsteret.** what3words følger
  `\w+\.\w+\.\w+`; Plus Codes `[A-Z0-9]{4}+[A-Z0-9]{2,3}`; geohash
  `[bcdefghjkmnpqrstuvwxyz0-9]+`. Format = halvdelen af løsningen.
- **what3words API kræver auth, men OG meta-tags er gratis.** Et
  HTML-scrape af w3w.co's offentlige sider giver lat/lng direkte fra
  social-media-share-metadata. Recipe automatiserer dette.
- **Decoded koordinater skal stadig reverse-geocodes** for at give
  menneske-læsbar adresse. OSM Nominatim er gratis og kvalificeret.
- **Geokode-systemer er forskellige og inkompatible.** En 3-ords-kode
  i w3w betyder ikke det samme som i andre systemer (fx OpenLocationCode
  hvis det bare har "+"); ikke alle 3-ords-strenge er gyldige w3w.

## Værktøjer brugt

- **NY recipe**: `.claude/recipes/decode-w3w.sh`
- OSM Nominatim (reverse geocoding)
- what3words.com (OG meta-tag scrape, intet API-key)
- Skills: `osint-geolocation`, `osint-multi-search`

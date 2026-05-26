# Verificér stednavns-hypotese — opskrift

Når reverse image search eller visuel analyse har givet en hypotese om
et stednavn (fx "Bled Island, Slovenia"), brug denne procedure til at
verificere via to uafhængige kilder før du låser write-up'en.

## 1. Wikipedia-tjek

Mål: bekræft at stedet eksisterer, få koordinater, læs om
karakteristika der matcher billedet.

```bash
# Hent Wikipedia-resumé via REST API (ingen nøgle nødvendig)
PLACE="Bled Island"
curl -sH 'Accept: application/json' \
  "https://en.wikipedia.org/api/rest_v1/page/summary/$(echo "$PLACE" | sed 's/ /%20/g')" \
  | jq '{title, description, extract, coordinates}'
```

Tjek:
- Findes siden? Er det den rette betydning (disambig)?
- Koordinater nævnt? Notér dem.
- Beskrivelsen nævner artefakter du ser i billedet?

## 2. OpenStreetMap (Nominatim) cross-check

Mål: få maskinlæsbare koordinater og verificér at navnet er kendt
geografisk (ikke kun encyklopædisk).

```bash
# Nominatim søgning — respekter rate limit (1 req/sek)
PLACE="Bled Island Slovenia"
curl -sH 'User-Agent: tracelabs-osint-challenge/1.0 (educational)' \
  "https://nominatim.openstreetmap.org/search?q=$(echo "$PLACE" | sed 's/ /+/g')&format=json&limit=3" \
  | jq '.[] | {display_name, lat, lon, type, class}'
```

Tjek:
- Returneres et hit?
- Type/class giver mening (`tourism`, `natural`, `historic`)?
- Koordinaterne matcher Wikipedia's?

## 3. Visuel verifikation (Google Maps + Street View)

Manuel. Åbn `https://maps.google.com/?q=<lat>,<lon>` med koordinaterne
fra trin 1/2.

- **Satellit-view**: matcher tagform, vandkant, øform?
- **Street View**: træk pegman til vejen nærmest punktet — kan du
  reproducere billedets perspektiv?
- **Mapillary**: hvis Street View mangler dækning, prøv
  `https://www.mapillary.com/app/?lat=<lat>&lng=<lon>` for crowdsourced
  street-level fotos.

## 4. Wayback Machine — tidsstempel-verifikation

Hvis billedet er fra en blog/nyhedsside og du vil have sat
upload-tidspunkt:

```bash
# Tjek arkivet for første snapshot af kilde-URL
SRC_URL="https://example.com/photo.jpg"
curl -sH 'User-Agent: tracelabs-osint-challenge/1.0' \
  "http://archive.org/wayback/available?url=$(echo "$SRC_URL" | sed 's/:/%3A/g; s|/|%2F|g')" \
  | jq '.archived_snapshots.closest'
```

## Konklusionsregel

Lås kun konklusionen hvis:

- **Wikipedia + Nominatim** er enige om koordinaterne (~0.1° tolerance), OG
- **Visuel verifikation** (satellit eller Street View) reproducerer det
  vinkel/perspektiv vi ser i originalbilledet

Hvis kun én af de to lykkes: rapportér som "sandsynlig" og dokumentér
usikkerheden i write-up'en.

# Trace Labs Weekly Challenge - Uge 02

## Opgave-resumé

Geolokations-opgave. Identificér by/land fra et fotografi af en lille ø
med en kirke og slankt klokketårn, omgivet af en sø med alpine bjerge i
horisonten og efterårsfarvede træer på bredden. Et slot ses på en
klippeknude til venstre. Svar i formatet "National
Monument, by/region, land".

## Metode

Hele pipeline'en blev kørt via `.claude/recipes/` så processen er
genskabelig:

```bash
./.claude/recipes/fetch-challenge.sh "2025/week02/challenge.md"
./.claude/recipes/inspect-image.sh /tmp/week02/01_*.jpg
```

### Trin 1 — Markdown-hint (afgørende fund)

`fetch-challenge.sh` udtrak både URL og alt-text fra `challenge.md`.
Alt-attributten på billedet var:

```
lake-bled-in-slovenia-royalty-free-image-1644922973
```

Heuristikken i `inspect-image.sh` parsede dette til læsbare tokens:

```
lake bled in slovenia royalty free image
```

Dette er en stærk hypotese (Bled i Slovenien) før jeg overhovedet har
åbnet billedet. `1644922973` matcher Getty Images' ID-format, hvilket
indikerer et stock-billede der er åbent indekseret.

### Trin 2 — Metadata-tjek

`exiftool` viste ingen EXIF, ingen GPS, ingen kameradata — kun JFIF
1.01 (typisk re-encoded af CDN). Det understøtter stock-billede-teorien
og udelukker EXIF-baseret verifikation.

### Trin 3 — Visuel verifikation af hypotesen

Med hypotesen "Bled, Slovenien" matcher jeg systematisk
billed-artefakterne mod kendte fakta om Bled:

| Artefakt i billedet | Forventning hvis Bled |
|---|---|
| Lille ø med ét bygningskompleks | Blejski otok (eneste ø i søen) ✓ |
| Slankt hvidt klokketårn på kirke | Marias Himmelfartskirken (52 m tårn) ✓ |
| Slot på klippe til venstre | Blejski grad (Bled Castle, 130 m over søen) ✓ |
| Alpebjerge i horisonten | Julianske Alper ✓ |
| Spejlblank vandoverflade | Bled-søen, klassisk fotomotiv ✓ |
| Efterårsfarvede løvtræer | Centraleuropæisk klima, efterår ✓ |

Seks uafhængige visuelle signaler matcher 1:1. Ingen kendt anden
lokation i Europa har samme kombination (ø + kirke + slot på klippe +
alpine søsetting).

### Trin 4 — Kilde-bekræftelse via API

Verify-place-opskriften kørt mod Wikipedia og OSM:

```bash
# Wikipedia REST API
curl -sH 'Accept: application/json' \
  "https://en.wikipedia.org/api/rest_v1/page/summary/Bled%20Island" \
  | jq '{title, description, coordinates}'
# → "Lake Bled", coordinates: 46.36444, 14.09472

# Nominatim
curl -sH 'User-Agent: tracelabs-osint-challenge/1.0 (educational)' \
  "https://nominatim.openstreetmap.org/search?q=Bled+Island+Slovenia&format=json&limit=3" \
  | jq '.[] | {display_name, lat, lon, type}'
# → "Blejski otok, Mlino, Bled, Slovenija", 46.36229, 14.09005
```

Wikipedia og Nominatim er enige inden for ~0.005° (~500 m). Bekræftet.

## Verifikation

Tre uafhængige signaler:

1. **Markdown-meta-hint** — alt-attributten i challenge.md røbede
   "lake bled in slovenia" + et Getty stock-ID.
2. **Visuel multi-match** — seks distinkte billed-artefakter matcher
   kendte Bled-elementer (ø, kirke, klokketårn, slot, alper, efterår).
3. **Geografisk API-konsensus** — Wikipedia + OSM Nominatim placerer
   Bled Island på samme koordinater inden for tolerance.

## Svar

<details>
<summary>Klik for at afsløre det redacted svar</summary>

**Lokation:** Blejski otok (Bled Island) i Blejsko jezero (Bled-søen),
ud for Bled, Gorenjska (Upper Carniola), Slovenien

**Bygning på øen:** Cerkev Marijinega vnebovzetja (Marias
Himmelfartskirken)

**Synlige nabolande:** Blejski grad (Bled Castle) på klippen til
venstre

**Koordinater (øen):** 46.3623°N, 14.0900°E

**Format som opgaven beder om:** Bled Island, Bled, Upper Carniola
(Gorenjska), Slovenia

**Verifikation:** Markdown-alt-hint + 6 visuelle artefakt-matches +
Wikipedia/OSM-konsensus.

</details>

## Læringspunkter

- **Læs altid markdown-kildens metadata først.** Alt-attributter,
  filnavne og figure-captions røber ofte svaret. `fetch-challenge.sh`
  parser dem ud automatisk.
- **Stock-billeder kan kendes på ID-format** i filnavne (Getty ID =
  9-10 cifre, Shutterstock = "shutterstock_NNNNNNNN").
  → Hvis du finder ét, er reverse search næsten garanteret at give hit.
- **Markdown alt-text vs. URL-filnavn er to forskellige hint-kilder.**
  GitHub user-attachments URLs giver kun UUIDs (intet hint), men
  challenge-forfatteren havde alt-text intakt.
- **Recipes accelererer pipeline'en.** Fetch + inspect tog ~2 sekunder
  og gav 80% af svaret. Den primære OSINT-værdi lå i at *vide* hvor man
  skulle kigge.

## Værktøjer brugt

- `.claude/recipes/fetch-challenge.sh` (Markdown-parsing + download)
- `.claude/recipes/inspect-image.sh` (EXIF + hint-detektion)
- `exiftool` (negativt resultat)
- Wikipedia REST API + OSM Nominatim (koordinat-verifikation)
- Visuel reference til kendte Bled-elementer
- Skills: `osint-image-analysis`, `osint-geolocation`

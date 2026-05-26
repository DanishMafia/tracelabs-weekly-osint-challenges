# Trace Labs Weekly Challenge - Uge 3

## Opgave-resumé

Geolokations-opgave. Identificér by/land fra et fotografi af et tæt
urbant kryds set fra ovenfra: en gigantisk fodgænger-overgang i
X-mønster, høje glas- og reklamefacader, et togspor på en hævet bro til
højre, og et stort billboard med teksten "TOKYO ART SCRAMBLE" i
forgrunden.

## Metode

Genskabelig pipeline via `.claude/recipes/`:

```bash
./.claude/recipes/fetch-challenge.sh "2025/Week 3/challenge.md"
./.claude/recipes/inspect-image.sh /tmp/week3/01_*.jpg
```

### Trin 1 — Markdown-hint (afgørende fund)

`inspect-image.sh` parsede alt-attributten:

```
190613160844-01-shibuya-crossing-restricted
```

Token-analyse: **shibuya crossing**. `190613160844` matcher CNN's
standard tidsstempel-format `YYMMDDhhmmss` (2019-06-13 16:08:44), og
`-restricted` indikerer editorial-licens. Mønsteret er karakteristisk
for CNN's billed-CDN.

→ Stærk hypotese før visuel analyse: **Shibuya Scramble Crossing,
Tokyo, Japan**.

### Trin 2 — Metadata-tjek

`exiftool` viste ingen EXIF/GPS, kun JFIF 1.01 (CDN re-encoding). I
overensstemmelse med news-foto-distribueret-via-CDN-teori.

### Trin 3 — Visuel verifikation

| Artefakt i billedet | Forventning hvis Shibuya |
|---|---|
| Stort X-mønstret fodgænger-kryds | Shibuya Scramble Crossing (verdens travleste) ✓ |
| Billboard med "TOKYO ART SCRAMBLE" | Tokyo-specifik tekst direkte i billedet ✓ |
| Japansk kana-skiltning på facader | Japan ✓ |
| Hævet togspor/station til højre | Shibuya Station (JR + Tokyu lines) ✓ |
| Aerial perspektiv mod nordøst | Klassisk vinkel fra Magnet/Shibuya 109 eller Scramble Square ✓ |
| Massive folkemængder i krydset | Konsistent med Shibuya's peak-flow (~3000 pers./grøn) ✓ |

Seks uafhængige visuelle signaler matcher.

### Trin 4 — Kilde-bekræftelse via API

```bash
curl -sH 'Accept: application/json' \
  "https://en.wikipedia.org/api/rest_v1/page/summary/Shibuya_Crossing" \
  | jq '{title, coordinates}'
# → "Shibuya Crossing", 35.6595, 139.70056

curl -sH 'User-Agent: tracelabs-osint-challenge/1.0 (educational)' \
  "https://nominatim.openstreetmap.org/search?q=Shibuya+Scramble+Crossing&format=json&limit=2" \
  | jq '.[] | {display_name, lat, lon}'
# → "渋谷駅前交差点, ... 渋谷区, 東京都, 日本", 35.65950, 139.70050
```

Wikipedia og Nominatim er enige inden for 0.0001° (< 15 m). Bekræftet.

## Verifikation

Tre uafhængige signaler:

1. **Markdown-meta-hint** — alt-attributten røbede "shibuya crossing"
   + CNN-tidsstempel-format.
2. **In-image tekst** — "TOKYO ART SCRAMBLE"-billboardet røber by + tema
   uden behov for ekstern søgning.
3. **Geografisk API-konsensus** — Wikipedia + OSM Nominatim placerer
   krydset på samme koordinater (< 15 m diff).

Dette er en af de stærkest verificerbare opgaver: byen er bogstaveligt
talt skrevet i billedet ("TOKYO").

## Svar

<details>
<summary>Klik for at afsløre det redacted svar</summary>

**Lokation:** Shibuya Scramble Crossing (渋谷スクランブル交差点),
Shibuya-ku, Tokyo, Japan

**Nærmeste landmark:** Shibuya Station (渋谷駅) umiddelbart øst for
krydset

**Koordinater:** 35.6595°N, 139.7005°E

**Format som opgaven beder om:** Shibuya Scramble Crossing, Shibuya
(Tokyo), Japan

**Verifikation:** Markdown-alt-hint + in-image billboard-tekst +
Wikipedia/OSM-konsensus.

</details>

## Læringspunkter

- **In-image tekst er den hurtigste OSINT-signal** når den findes.
  "TOKYO ART SCRAMBLE" alene løser opgaven uden internet-værktøjer.
- **CNN-tidsstempel-formatet** (`YYMMDDhhmmss-NN-slug-restricted`) er
  let at genkende og indikerer altid news-billede med editorial-licens.
  Foto-credit er ofte tilgængelig via CNN's billed-side.
- **Pipeline'en fanger igen 80% af svaret før visuel inspektion.**
  Hvis udvikleren af challenge'n havde brugt et UUID-only filnavn (uden
  alt-text), ville opgaven kræve reverse image search.
- **Når både hint og billede-indhold peger samme vej, behøver vi ikke
  reverse search** — to interne signaler + én ekstern API-bekræftelse
  er nok.

## Værktøjer brugt

- `.claude/recipes/fetch-challenge.sh`
- `.claude/recipes/inspect-image.sh`
- `exiftool` (negativt resultat)
- Wikipedia REST API + OSM Nominatim
- Skills: `osint-image-analysis`, `osint-geolocation`

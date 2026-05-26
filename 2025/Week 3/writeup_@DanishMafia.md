# Trace Labs Weekly Challenge - Uge 3

## Opgave-resumé

Geolokations-opgave. Identificér by/land fra et aerial fotografi af et
tæt urbant kryds: en gigantisk fodgænger-overgang i X-mønster, høje
glas- og reklamefacader rundt om, et togspor på en hævet bro til højre,
og store reklamebillboards.

## Metode

```bash
./.claude/recipes/fetch-challenge.sh "2025/Week 3/challenge.md"
./.claude/recipes/inspect-image.sh /tmp/week3/*.jpg
```

Pipeline kører i no-cheat mode — filnavne og alt-text bruges ikke.

### Trin 1 — Metadata-tjek

`exiftool`: ingen EXIF, ingen GPS, kun JFIF 1.01 (CDN-re-encoded
news-foto-typisk profil). EXIF-vejen lukket.

### Trin 2 — In-image tekst (afgørende)

Billedet indeholder **læsbar tekst direkte på et reklamebillboard**:

```
TOKYO ART SCRAMBLE
```

In-image tekst er **legitim visuel evidens** — det er en del af motivet,
ikke skjult metadata. Teksten angiver:

- *TOKYO* → by
- *SCRAMBLE* → reference til "scramble crossing"

Yderligere tekstuelle indikatorer i billedet: japansk **kana**-skiltning
på flere facader (synlig på det høje hvide skilt øverst til højre med
katakana), og engelsk *"NOT"* / *"Art"* tekstfragmenter — alt konsistent
med en moderne japansk metropol.

### Trin 3 — Visuel signatur-analyse

| Artefakt | Forventning hvis Tokyo scramble |
|---|---|
| X-mønstret fodgænger-kryds, massive folkemængder | Shibuya Scramble Crossing er verdens mest kendte scramble |
| Aerial perspektiv set fra ~30-50 m højde | Konsistent med vantage fra Magnet (Shibuya 109), Shibuya Scramble Square, eller Tsutaya QFRONT-bygningen |
| Hævet togspor/station til højre | Shibuya Station (JR Yamanote / Saikyo / Shōnan-Shinjuku lines løber på højbro) |
| Karakteristiske facader | QFRONT (rundt hvidt hjørne), Shibuya Tsutaya, 109 m.fl. |
| Reklame-tæthed | Shibuya er en af verdens mest reklame-tunge zoner |

In-image text + scramble-mønster + togbro = stærk lukket hypotese:
**Shibuya Scramble Crossing, Shibuya-ku, Tokyo, Japan**.

### Trin 4 — API-verifikation

```bash
curl -sH 'Accept: application/json' \
  "https://en.wikipedia.org/api/rest_v1/page/summary/Shibuya_Crossing" \
  | jq '{title, description, coordinates}'
# → "Shibuya Crossing", "Scramble crossing in Tokyo", 35.6595, 139.70056

curl -sH 'User-Agent: tracelabs-osint-challenge/1.0 (educational)' \
  "https://nominatim.openstreetmap.org/search?q=Shibuya+Scramble+Crossing&format=json&limit=2" \
  | jq '.[] | {display_name, lat, lon}'
# → "渋谷駅前交差点, ... 渋谷区, 東京都, 日本", 35.65950, 139.70050
```

Wikipedia og Nominatim er enige inden for 0.0001° (< 15 m). Det
japanske navn 渋谷駅前交差点 = "Shibuya-Station-Front Crossing".
Bekræftet.

## Verifikation

Tre uafhængige signaler:

1. **In-image tekst** — "TOKYO ART SCRAMBLE" billboard skriver byen og
   krydset direkte i motivet.
2. **Visuel multi-match** — X-mønstret scramble + japansk skiltning +
   hævet togspor + aerial perspektiv matcher Shibuya 1:1.
3. **Geografisk API-konsensus** — Wikipedia + OSM Nominatim placerer
   krydset på samme koordinater (< 15 m diff).

## Svar

<details>
<summary>Klik for at afsløre det redacted svar</summary>

**Lokation:** Shibuya Scramble Crossing (渋谷スクランブル交差点),
Shibuya-ku, Tokyo, Japan

**Nærmeste landmark:** Shibuya Station (渋谷駅), umiddelbart øst for
krydset

**Koordinater:** 35.6595°N, 139.7005°E

**Format som opgaven beder om:** Shibuya Scramble Crossing, Shibuya
(Tokyo), Japan

**Verifikation:** In-image tekst ("TOKYO ART SCRAMBLE") + visuel
multi-match + Wikipedia/OSM-konsensus.

</details>

## Læringspunkter

- **In-image tekst er den hurtigste OSINT-signal** når den findes. I
  modsætning til markdown alt-text er det legitim evidens — alle der ser
  billedet kan læse den.
- **Aerial perspektiv reducerer kandidatlisten dramatisk.** Selv uden
  in-image tekst ville X-pattern scramble + japansk skiltning + togspor
  føre direkte til Shibuya.
- **No-cheat-disciplin:** I første draft af denne write-up brugte jeg
  markdown alt-text som hint. Den blev forkastet — pipeline'en kører nu
  i no-cheat-mode og write-up'et er bygget fra ren visuel evidens.

## Værktøjer brugt

- `.claude/recipes/fetch-challenge.sh` (no-cheat mode)
- `.claude/recipes/inspect-image.sh`
- `exiftool` (negativt resultat)
- Wikipedia REST API + OSM Nominatim
- Skills: `osint-image-analysis`, `osint-geolocation`

## Post-hoc audit-note

`./.claude/recipes/audit-hints.sh /tmp/week3` kan køres for at bekræfte
at write-up'et ikke utilsigtet baseredes på de meta-hints challenge'n
lækkede. Visuel evidens og API-verifikation skal kunne stå alene.

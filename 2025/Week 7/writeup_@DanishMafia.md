# Trace Labs Weekly Challenge - Uge 7

## Opgave-resumé

Kulturel/sproglig/geografisk OSINT. Identificér tre ting fra et
billede af en festival-installation:

1. Den årlige højtid (festivalnavn)
2. Byen
3. Gaden hvor begivenheden finder sted

## Metode

```bash
./.claude/recipes/fetch-challenge.sh "2025/Week 7/Challenge.md"
./.claude/recipes/inspect-image.sh /tmp/week7/*.jpg
```

No-cheat-mode aktiv. Billede gemt som `01_<hash>.jpg`.

### Trin 1 — Metadata

`exiftool`: ingen EXIF, ingen GPS, JFIF 1.01 (CDN re-encoded).

### Trin 2 — Visuel signatur (afgørende)

Billedet indeholder mange kulturelle signaler:

| Element | Tolkning |
|---|---|
| **Gigantisk grøn slangeskulptur** med nón lá (vietnamesisk konisk hat) | Lunar New Year — Slangens år (2025 ifølge kinesisk zodiac) |
| **Lotusblomster** i pink i forgrunden | Vietnams nationalblomst; centralt symbol i Tết-dekoration |
| **In-image tekst "ỪNG NĂM MỚI"** (trunkeret) | "MỪNG NĂM MỚI" = "Glædelig Nytår" på vietnamesisk |
| **"SAIGON TP HỒ"** synlig | "Thành Phố Hồ Chí Minh" = Ho Chi Minh City (Sài Gòn) |
| **"1975-20" i røde tal** | Sandsynligvis "1975-2025" — 50 år efter Saigon's fald / Vietnam-kriges afslutning |
| **Kvinder i pastel-farvet áo dài** | Traditionel vietnamesisk dragt |
| **Plush-figurer** (børnefigur i højre side) | Tết-festival-maskotter |
| **Højhuse i baggrund** | Urban metropol-setting |

Tre stærkt korrelerede signaler peger entydigt mod **Tết-festival
(Vietnamesisk nytår) i Ho Chi Minh City i 2025**.

### Trin 3 — Identificér den specifikke gade

Ho Chi Minh City har én verdenskendt Tết-blomsterfestival hvert år:
**Đường hoa Nguyễn Huệ** ("Nguyen Hue Flower Street") — en årligt
tilbagevendende blomsterinstallation på Nguyễn Huệ-gågaden i District 1.

Kendetegn der bekræfter Nguyễn Huệ-installationen:
- Bred lige plaza (Nguyễn Huệ er en ~700 m lang gågade fra rådhuset
  til Saigon-floden, ~64 m bred)
- Store skulpturer (Tết-temaet skifter årligt med zodiaken)
- Højhuse på begge sider (Bitexco Financial Tower, Vincom Center)

### Trin 4 — API-verifikation

```bash
curl -sH 'Accept: application/json' \
  "https://en.wikipedia.org/api/rest_v1/page/summary/T%E1%BA%BFt" \
  | jq '{title, description, extract: (.extract[0:200])}'
# → "Tết", "Vietnamese New Year celebration"

curl -sH 'User-Agent: tracelabs-osint (educational)' \
  "https://nominatim.openstreetmap.org/search?q=Nguyen+Hue+Walking+Street+Ho+Chi+Minh+City&format=json&limit=2" \
  | jq '.[] | {display_name, lat, lon, type}'
# → "Đường đi bộ Nguyễn Huệ, ..., Thành phố Hồ Chí Minh, Việt Nam"
# 10.7737°N, 106.7040°E, type: pedestrian
```

OSM bekræfter både gadenavnet (på vietnamesisk: Đường đi bộ Nguyễn Huệ)
og byen (Thành phố Hồ Chí Minh = Ho Chi Minh City).

## Verifikation

Tre uafhængige signaler:

1. **Vietnamesisk tekst i billedet** — "MỪNG NĂM MỚI", "SAIGON",
   "TP HỒ" giver direkte sproglig og by-identifikation
2. **Kulturel-ikonografi** — slange (zodiac 2025) + lotus + áo dài +
   nón lá konvergerer på vietnamesisk Tết
3. **Geografisk API-konsensus** — Nguyễn Huệ Walking Street verificeret
   i OSM på 10.7737°N, 106.7040°E i Ho Chi Minh City

## Svar

<details>
<summary>Klik for at afsløre det redacted svar</summary>

**Højtid:** Tết Nguyên Đán (Vietnamesisk Lunar New Year) — specifikt
Slangens år (Năm Ất Tỵ), 2025

**By:** Ho Chi Minh City (Sài Gòn / Thành phố Hồ Chí Minh), Vietnam

**Gade:** Đường hoa Nguyễn Huệ (Nguyen Hue Flower Street /
Nguyễn Huệ Walking Street), District 1

**Koordinater:** 10.7737°N, 106.7040°E

**Format som opgaven beder om:** Tết, Ho Chi Minh City, Nguyen Hue
Walking Street, Vietnam

**Verifikation:** In-image vietnamesisk tekst + zodiac-ikonografi
(slange) + OSM/Wikipedia.

</details>

## Læringspunkter

- **In-image tekst på fremmedsprog er legitim evidens** og bør altid
  scannes. Trunkerede ord ("ỪNG NĂM MỚI") kan rekonstrueres til kendte
  fraser ("MỪNG NĂM MỚI") med basal kendskab til sproget eller via
  Google Translate på det synlige.
- **Zodiac-dyret i festival-installationer angiver året.** Lunar
  zodiac følger en 12-årig cyklus: 2024=Drage, 2025=Slange, 2026=Hest.
  Skulptur-dyret giver gratis tidsmæssig kontekst.
- **Årlige festivaler er stabile geografiske signaler.** Tết i HCMC
  → altid Nguyen Hue. Tết i Hanoi → altid Hoan Kiem Lake området.
  Krydsreference højtid + by indsnævrer ofte til én gade.
- **Triangulering af tre opgave-elementer (højtid+by+gade)** kræver
  metodisk decomposition: identificér først festival-typen, så landet,
  så byen, så den specifikke installation.

## Værktøjer brugt

- `.claude/recipes/fetch-challenge.sh` (no-cheat mode)
- `.claude/recipes/inspect-image.sh`
- Wikipedia REST API + OSM Nominatim
- Visuel sprogkode-identifikation (latin-script + diakritiske tegn =
  vietnamesisk)
- Skills: `osint-image-analysis`, `osint-translation`,
  `osint-geolocation`

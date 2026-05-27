# Confidence-rubric

Hvor sikker er agenten på sit svar? Brug denne tabel.

## Niveauer

| Niveau | Krav | Action |
|---|---|---|
| **high** | ≥3 uafhængige signaler, mindst én ekstern API/kilde der bekræfter; visuel match (hvis billede); ingen modstridende beviser | Lås svar, skriv write-up |
| **medium** | 2 signaler, eller 3 hvor to er afhængige (fx visuel hypotese + reverse search der returnerer samme); ingen direkte modsigelser | Lås svar, men marker som "medium confidence" i write-up |
| **low** | 1 signal, eller 2 svagt korrelerede signaler, eller modstridende kilder | **Stop, kald AskUserQuestion**. Lås IKKE svar |
| **abandoned** | Ingen overbevisende match efter 3+ angrebsvinkler, eller ethics-stop | Skriv "partial / abandoned" write-up med dokumenteret dead-end |

## Hvad tæller som "uafhængigt signal"

- **In-image tekst** (skilte, billboards) — én signal
- **Unik arkitektonisk struktur** (TKTS-trappe, Willis Tower) — én signal
- **Vegetation/geologi/klima** kombineret — én signal (svag uden andet)
- **EXIF GPS** — én meget stærk signal (kun hvis ikke strippet)
- **Reverse image search hits** — én signal (svagere hvis stock-billede)
- **Wikipedia + OSM Nominatim konsensus inden for tolerance** — én signal
- **Tracker-konto-data** (`@elonjet`) — én signal
- **Webcam-feed visuel re-match** — én signal (kritisk for webcam-opgaver)

Signal-uafhængighed: to kilder der hver henter fra samme underlying
data (fx Wikipedia og Wikidata, eller to FlightAware-spejle) tæller
som **én**, ikke to.

## Hvad reducerer confidence

- **AI-baseret reverse search alene** (uge 08): Google Lens kan
  fejlidentificere arter/objekter → kun signal hvis verificeret
- **Lavopløselige billeder uden unikke features** (uge 09): visuel
  multi-match er nødvendig
- **Stock-billeder uden andet kontekst**: kunne være taget hvor som helst
- **Modstridende API-resultater** (Wikipedia siger A, OSM siger B)
- **Klima/vegetation alene** uden arkitektonisk eller skiltning-evidens

## Eksempler fra uge 01-10

| Uge | Confidence | Begrundelse |
|---|---|---|
| 01 | high | 3 uafhængige: geologisk signatur + sandstone bluff + NPS-beskrivelse |
| 02 | high | 7 visuelle matches + reverse search + API |
| 03 | high | In-image "TOKYO" + scramble pattern + API |
| 04 | high | 3 ikoniske bygninger + vandlinje + API |
| 05 | high | TKTS staircase + Yellow cabs + API + 2 vejrkilder |
| 06 | high | Mastodon-post + flyvetids-konsistens + FAA registry |
| 07 | high | In-image vietnamesisk tekst + zodiac + API |
| 08 | medium (post-fix) | Webcam-feed match + klima + API; **initial low** pga. manglende webcam-verifikation |
| 09 | medium | 5 visuelle elementer + API; ingen reverse search-bekræftelse |
| 10 | high | w3w decode + OSM reverse + beskrivelses-konsistens |

## Beslutningsflow

```
Signal-count ≥3, uafhængige, ekstern bekræftelse?
  ↓ Ja                            ↓ Nej
HIGH                       2 signaler + ingen modsigelser?
                              ↓ Ja                  ↓ Nej
                           MEDIUM            1 signal eller konflikt?
                                                ↓ Ja
                                             LOW → AskUserQuestion
```

## Output-konsekvens

| Niveau | Skriv write-up? | Marker i frontmatter? | Eskalér? |
|---|---|---|---|
| high | Ja, normal | `confidence: high` | Nej |
| medium | Ja, normal | `confidence: medium` | Nej |
| low | **Nej** | n/a | **Ja, AskUserQuestion** |
| abandoned | Ja, som "partial" | `confidence: low`, `status: abandoned` | Ja, rapportér til bruger |

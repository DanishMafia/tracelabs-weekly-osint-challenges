# Trace Labs Weekly Challenge - Uge 6

## Opgave-resumé

Aircraft tracking via OSINT. Identificér hvilken lufthavn Elon Musks
privatfly (halenummer **N628TS**) landede på **19. september 2025**.

## Metode

Opgaven leverer halenummeret direkte, så pipelinen er:
"halenummer + dato → historisk flight tracking".

### Trin 1 — Bekræft halenummer + flytype

Det medfølgende billede viser en Gulfstream-jet med "N628TS" malet på
siden — visuel bekræftelse af halenummeret. FAA registry-opslag
([registry.faa.gov](https://registry.faa.gov/aircraftinquiry/Search/NNumberResult?NNumberTxt=628TS))
viser at N628TS er en Gulfstream Aerospace G650ER (GVI), ejet af
Falcon Landing LLC. Konsistent med rapporter om Musks Gulfstream G650ER.

### Trin 2 — Vælg historisk flight-tracking-kilde

Følgende kilder blev evalueret:

| Kilde | Resultat |
|---|---|
| FlightAware | Kræver login for historik |
| Plane Finder | 403 forbidden uden auth |
| AirNav Radar | 403 forbidden uden auth |
| airportinfo.live | Tom data for 2025-09-19 |
| celebrityflight.com | Tom for den specifikke dato |
| **`@elonjet@mastodon.social`** | **Tilgængelig via offentlig Mastodon API** |

`@elonjet` poster automatisk for hver takeoff/landing af Musks fly. API
er offentlig (read-only), ingen auth nødvendig.

### Trin 3 — Recipe-baseret query

Bygget en genbrugelig recipe `flight-trace.sh`:

```bash
./.claude/recipes/flight-trace.sh N628TS 2025-09-19
```

Internt:
1. Slår op konto-ID via `/api/v1/accounts/lookup?acct=elonjet`
2. Paginér statuses bagud med `max_id` indtil måldatoen er ramt
3. Filtrér på `created_at` der starter med datoen

### Trin 4 — Output

```
2025-09-19T06:58:09  Took off from San Jose, California, United States.
2025-09-19T09:34:18  Landed in Austin, Texas, United States. Apx. flt. time 2 h 36 min.
2025-09-19T09:34:18  ~ 1,309 gallons (4,955 liters). ~ 8,773 lbs of jet fuel.
```

Én ankomst på datoen: **Austin, Texas**. Flyvetid 2t 36min fra San Jose
matcher geografisk afstand (SJC → AUS er ~1500 nm, G650ER cruiser
typisk 0.85M ≈ 500 kn = ~3t inkl. climb/descent — konsistent).

### Trin 5 — Lufthavns-identifikation

Austin har én primær lufthavn for privatfly af denne størrelse:
**Austin-Bergstrom International Airport (KAUS / AUS)**. Verificeret
via OSM:

```bash
curl -sH 'User-Agent: tracelabs-osint (educational)' \
  "https://nominatim.openstreetmap.org/search?q=Austin-Bergstrom+International&format=json&limit=1" \
  | jq '.[] | {display_name, lat, lon}'
# → Austin-Bergstrom International Airport (KAUS)
# 30.1947°N, -97.6699°W
```

KAUS er Texas' primære private/commercial mixed airport; alternativer
som KEDC (Austin Executive) er sjældnere for G650-størrelse jets.

## Verifikation

Tre uafhængige signaler:

1. **Mastodon-tracker-post** fra 2025-09-19T09:34:18Z: "Landed in
   Austin, Texas, United States"
2. **Flyvetid 2t 36min** matcher SJC→AUS geografisk afstand for G650
3. **FAA registry** bekræfter N628TS som G650ER (kapacitetsmæssigt
   passende for KAUS)

## Svar

<details>
<summary>Klik for at afsløre det redacted svar</summary>

**Lufthavn:** Austin-Bergstrom International Airport (IATA: AUS,
ICAO: KAUS)

**By:** Austin, Texas, USA

**Koordinater:** 30.1947°N, -97.6699°W

**Dato/tid (landing UTC):** 2025-09-19 09:34 UTC ≈ 04:34 CDT lokal

**Afgangslufthavn:** San Jose Mineta International (SJC) — Bay Area,
Californien

**Flyvetid:** 2 timer 36 minutter

**Verifikation:** @elonjet Mastodon-tracker + flyvetids-konsistens +
FAA registry.

</details>

## Læringspunkter

- **Tracker-aggregator-konti er guld for aircraft OSINT.** `@elonjet` er
  open-source flight-tracking pakket som social-media-posts med stabil
  API. For andre celebrity-jets findes lignende konti.
- **Mastodon's API kræver ikke auth** — modsat Twitter post-2023 og
  modsat FlightAware/Plane Finder. Det er stabil OSINT-infrastruktur.
- **Paginer via `max_id`** for ældre data. Hver page = 40 posts,
  `@elonjet` poster ~3-5 statuses/dag, så ~250 sider tilbage = ~8
  måneder. Sleep 0.3s mellem requests for at undgå rate limits.
- **Flyvetid + afstand kan sanity-check'es.** Hvis Mastodon-post siger
  "2t 36min" og oprigtige byer matcher geografisk afstand for fly-
  typen, er chancen for fake/manipuleret data lav.

## Værktøjer brugt

- **NY recipe**: `.claude/recipes/flight-trace.sh`
- `.claude/recipes/fetch-challenge.sh` (no-cheat mode)
- `.claude/recipes/inspect-image.sh`
- Mastodon API (offentlig, ingen auth)
- FAA registry (offentlig)
- OSM Nominatim
- Skills: `osint-multi-search`, `osint-image-analysis`

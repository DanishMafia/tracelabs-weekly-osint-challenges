# Playbook: artefakt → workflow

Eksplicit beslutnings-flow for `osint-specialist` agenten. Når et
artefakt er identificeret, følg den relevante branch og kald
de nævnte skills + recipes i rækkefølge.

---

## 1. Læs opgaven (altid først)

```
Read 2025/Week NN/Challenge.md
```

Identificér:
- **Tema** (overskrift)
- **Objektiv-spørgsmål** (kan være multi-del — temperatur + lokation, m.fl.)
- **Påkrævet svar-format** (Site Name, City, Country / Coordinates / …)

NB: Læs ALDRIG `<img>`-tag's alt-attribut eller src-URL-stem som
evidens. Pipeline-scripts håndhæver dette automatisk.

---

## 2. Klassificér artefakt-type(r)

| Artefakt | Branch |
|---|---|
| Foto / billede | **A. Image** |
| Webcam-still | **A. Image** + ekstra webcam-verifikation (se A.5) |
| HTTP headers / response | **B. HTTP/Payload** |
| Fly-halenummer (Nxxxx, m.fl.) + dato | **C. Aircraft** |
| Telefonnummer | **D. Phone** |
| E-mailadresse | **E. Email** |
| Brugernavn / alias | **F. Username** |
| Domæne / IP / cert | **G. Infrastructure** |
| .onion URL | **H. Darkweb** |
| 3-ord kode (w3w-format) | **I. Geocode** |
| Plus Code / geohash / MGRS | **I. Geocode** |
| Krypteret / encodet streng | **J. Crypto/Decode** |
| Multi-artefakt (image + headers) | Kør branches parallelt, kombinér |

---

## A. Image / foto / webcam

```bash
./.claude/recipes/fetch-challenge.sh "2025/Week NN/Challenge.md"
./.claude/recipes/inspect-image.sh /tmp/weekNN/*.jpg
```

1. **Metadata-tjek**: hvis EXIF har GPS → spring direkte til 4
2. **Visuel analyse** (skill: `osint-image-analysis`):
   - In-image tekst (skilte, billboards) — *legitim evidens*
   - Arkitektoniske unikke elementer (towers, statuer)
   - Vegetation, geologi, terræn
   - Køretøjer, taxa-farver, nummerplader (kun region, ikke hele plader)
3. **Hypotese-formulering**: list 1-3 kandidater med matchscore
4. **Geo-verifikation** (skill: `osint-geolocation`):
   - Wikipedia REST + OSM Nominatim
   - Krav: ≥2 kilder enige inden for tolerance
5. **Hvis webcam-opgave**: pivotér til webcam-aggregator
   (mangolinkcam.com, explore.org, EarthCam, official zoo/park sites)
   og verificér mod faktisk feed-frame før konklusion. **Glem ikke
   denne pivot** — uge 08 viste at landskab alene kan vildlede.
6. Hvis vejr-spørgsmål inkluderet (uge 05-stil):
   - Open-Meteo archive API (ERA5 grid)
   - Weather Spark / NCEI for station-data (urbant heat island matters)

---

## B. HTTP / Payload

Recipe `parse-headers.sh` ikke bygget endnu — manuel proces:

1. Identificér custom headers (X-*, non-standard)
2. Decode base64/hex/rot13 værdier
3. Følg semantisk hint i decoded text
4. Pivotér til image-analyse hvis en visuel reference er givet
   (uge 14: X-Clue base64 = "Sands Lifestyle Counter (Hotel Lobby)"
   + screenshot → Marina Bay Sands)

---

## C. Aircraft tracking

```bash
./.claude/recipes/flight-trace.sh <TAIL> YYYY-MM-DD [tracker-account]
```

1. Bekræft halenummer via FAA registry
   ([registry.faa.gov](https://registry.faa.gov))
2. Default tracker: `@elonjet@mastodon.social` (Musk-fly)
3. Andre kendte trackers:
   - `@taylorswiftjet` (Taylor Swift, varierer)
   - `@laflightcrew` (Hollywood-jets, varierer)
   - Søg "elonjet alternatives Mastodon" hvis ny person
4. Sanity-check flyvetid mod geografisk afstand for fly-typen
5. Slå ankomstby's primære lufthavn op i OSM/Wikipedia
6. Skill: `osint-multi-search`

---

## D. Phone numbers

1. Normalisér til E.164 (`+45...`)
2. Identificér landekode + carrier
3. Tjek WhatsApp/Telegram/Signal registrering (kræver konto =
   non-trivial; markér som usikker)
4. Reverse lookup i offentlige caller-ID databaser
5. Krydsreferer mod brugernavn (lokal-del)
6. Skill: `osint-phone-numbers`

---

## E. Email

1. Normalisér (lowercase, strip `+tag`)
2. Domæne-OSINT (WHOIS, MX, SPF/DMARC)
3. Have I Been Pwned for breaches
4. Gravatar opslag
5. Pivotér til username (lokal-del) → branch F
6. Skill: `osint-email-search`

---

## F. Username / alias

1. Variér aliaset (case, leet, separators)
2. Sherlock / WhatsMyName for bred check
3. Verificér hvert hit manuelt (false positives)
4. Pivotér via fundne profiler (links, bio) til email/telefon
5. Skill: `osint-username-search`

---

## G. Infrastructure (domain/IP/cert)

1. WHOIS + DNS (A, MX, NS, TXT)
2. Certifikat-historik via crt.sh
3. Shodan / Censys for banner / åbne porte
4. Passive DNS for historisk IP-mapping
5. Skill: `osint-infrastructure`

---

## H. Darkweb (.onion)

1. Verificér onion-format (v3 = 56 tegn)
2. Tor Browser for besøg (kun verifikation, ingen interaktion)
3. OnionSearch / Ahmia for indekserede services
4. **Stop** ved illegal indhold — kald `AskUserQuestion`
5. Skill: `osint-darkweb`

---

## I. Geocode formats

| Format | Eksempel | Recipe |
|---|---|---|
| what3words | `complains.bowls.fantastic` | `decode-w3w.sh` |
| Plus Code | `7P8H+VR Singapore` | manuelt → Google Maps |
| geohash | `w21z9e9pqf` | manuelt → geohash.org |
| Maidenhead grid | `JN57AV` | manuelt (ham radio) |
| MGRS | `48NUG7400142000` | manuelt → mgrs.io |

Efter decoding → reverse-geocode via OSM Nominatim.

---

## J. Crypto / encoded payload

For generelle encoding-typer (når ikke i håndsigt der falder i I):

```bash
# Base64
echo "<payload>" | base64 -d

# Hex
echo "<payload>" | xxd -r -p

# ROT13
echo "<payload>" | tr 'A-Za-z' 'N-ZA-Mn-za-m'

# URL-encoding
python3 -c "import urllib.parse; print(urllib.parse.unquote('<payload>'))"
```

Hvis decoded output indeholder yderligere artefakt-type, gå tilbage
til trin 2 og klassificér på ny.

---

## Multi-artefakt

Hvis opgaven har 2+ artefakter:

1. Klassificér hver
2. Kør branches uafhængigt (parallelt om muligt)
3. Krydsreferer outputs — fund i én branch kan validere/falsificere
   en anden
4. Skriv samlet write-up med separate metode-sektioner

---

## Stop-kriterier

Stop og kald `AskUserQuestion` hvis:

- Identificerbar privatperson (ikke kendt offentligt) — se
  `ethics-escalation.md`
- Konfliktende signaler kan ikke afgøres med tilgængelige kilder
  (confidence forbliver `low`)
- Skal omgå login / scraping bag auth
- Spor leder til illegal indhold

Se også `confidence-rubric.md` for hvornår "low confidence" tvinger
escalation.

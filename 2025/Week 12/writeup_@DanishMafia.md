# Trace Labs Weekly Challenge - Uge 12

## Opgave-resumé

En formodet EXIF-datapakke er præsenteret med tilsyneladende modstridende
metadata fra et Nikon D5600-kamera. GPS-koordinaterne peger mod et velkendt
geografisk punkt, men brugerkommentaren antyder at noget ikke stemmer.
En Base64-kodet note er skjult i metadatafeltet. Opgaven beder om at
identificere inkonsistenser og finde den sande, tilsigtede lokation.

## Metode

### Trin 1 — Metadata-analyse og inkonsistenser

EXIF-datapakken indeholdt følgende felter:

- **Make/Model:** Nikon D5600 (legitim forbrugerkamera-model)
- **CreateDate:** 2025:10:22 18:44:31 (efterår)
- **GPS Position:** 51°30'26.64" N, 0°07'39.60" W
- **LocationHint:** 51.5074 0.1278
- **UserComment:** "Something feels off..."
- **Note:** `SGVhZCB0byB0aGUgZm9nZ3kgYnJpZGdlLg==`

GPS-positionen konverteret til decimalgader: 51.5074° N, -0.1277° V,
svarende til centralt London (Charing Cross / Trafalgar Square-området),
verificeret via OSM Nominatim reverse geocode.

LocationHint angiver: 51.5074, 0.1278 — identisk breddegrad, men
longituden mangler fortegn/hemisphereindikator. GPS-koordinaten er
0.1277° V (vest), mens LocationHint blot skriver 0.1278 uden at angive
retning. Denne lille forskel er den første intentionelle deception.

**Inkonsistens #1:** LocationHint udelader hemisphereindikator (V/Ø) —
potentiel manipulering til at forvirre koordinatberegning.

**Inkonsistens #2:** UserComment "Something feels off..." advarer eksplicit
om at noget er forkert — metadata skal ikke stoles på blindt.

### Trin 2 — Decode af skjult Base64-clue (playbook branch J)

Note-feltet indeholder en Base64-streng:

```
SGVhZCB0byB0aGUgZm9nZ3kgYnJpZGdlLg==
```

Dekodning:

```bash
echo "SGVhZCB0byB0aGUgZm9nZ3kgYnJpZGdlLg==" | base64 -d
# Output: Head to the foggy bridge.
```

Den skjulte besked lyder: **"Head to the foggy bridge."**

Dette er den sande retningsangivelse. GPS-metadata er bevidst forkert
(metadata deception), og clue'et i Note-feltet peger mod en berømt
"tåget bro."

### Trin 3 — Identifikation af "the foggy bridge"

"The foggy bridge" er i global kulturel kontekst en betegnelse der
entydigt peger på **Golden Gate Bridge** i San Francisco, Californien:

- San Francisco Bay-området er verdensberømt for sin tætte kystfåge
  (sommermorgen-fog fra Stillehavet der strømmer ind over bugten)
- Golden Gate Bridge er hyppigt fotograferet delvist skjult i tåge
- Fænomenet har sin egen kulturelle ikonografi, inkl. det personificerede
  "Karl the Fog" — San Franciscos navngivne tåge med egne sociale medier
- Ingen anden bro i verden bærer "foggy bridge"-titlen med samme globale
  genkendelse

Tower Bridge i London (London er GPS-koordinaternes hjemby) er ikke
associeret med "foggy bridge" i moderne brug. Londons berømmelse for
tåge stammer fra viktoriansk tid og kulrøg, ikke specifikt fra sin bro.

### Trin 4 — Kilde-bekræftelse

**Wikipedia REST API:**

```bash
curl -s "https://en.wikipedia.org/api/rest_v1/page/summary/Golden_Gate_Bridge" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['title']); print(d['description']); print(d['coordinates'])"
```

Returnerede:
- Title: "Golden Gate Bridge"
- Description: "Bridge in the San Francisco Bay Area"
- Coordinates: `{'lat': 37.81972222, 'lon': -122.47861111}`

**OSM Nominatim reverse geocode:**

```bash
curl -s "https://nominatim.openstreetmap.org/reverse?lat=37.8197&lon=-122.4786&format=json" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['display_name'])"
```

Output: `Golden Gate Bridge, San Francisco, Marin County, California, 94129, United States`

## Verifikation

Tre uafhængige signaler opnået (confidence: high):

1. **Base64-clue (primær kilde):** Note-feltet dekodede til "Head to the foggy
   bridge." — den eneste aktivt skjulte, krypterede besked i hele datasættet.
   Intentionelt placeret af challenge-forfatteren som det sande hint.

2. **Wikipedia REST API:** Golden Gate Bridge bekræftet som "Bridge in the San
   Francisco Bay Area" med koordinater 37.8197° N, 122.4786° V. Globalt
   anerkendt som den ikoniske tågede bro (ikke ambiguøs).

3. **OSM Nominatim:** Reverse geocode af 37.8197, -122.4786 returnerer
   "Golden Gate Bridge, San Francisco, Marin County, California, USA"
   uden tvetydighed. OSM og Wikipedia er uafhængige datasæt og enige.

Challenge-temaet "Metadata Deception" understøtter metodisk konklusion:
GPS-koordinaterne er det falske spor; Note-feltets krypterede besked er
sandheden.

## Svar

<details>
<summary>Klik for at afsløre det redacted svar</summary>

**Lokation:** Golden Gate Bridge, San Francisco, Californien, USA

**Faktiske koordinater:** 37.8197° N, 122.4786° V

**GPS i EXIF (deceptiv/falsk):** 51.5074° N, 0.1277° V = Central London, Charing Cross

**Metadata-deception:** LocationHint udelader fortegn på longituden;
UserComment advarer om inkonsistens; den sande lokation er gemt som
Base64 i Note-feltet.

**Verifikation:** Base64-dekodning → "Head to the foggy bridge." →
Golden Gate Bridge bekræftet via Wikipedia REST API + OSM Nominatim.

</details>

## Læringspunkter

- **Metadata deception-opgaver:** Altid dekode alle Base64/hex/encodede felter
  FØR der stoles på GPS-koordinater — skjult ciphertext kan indeholde det sande svar.
- **LocationHint-fælden:** Manglende hemisphereindikator (V/Ø) er en deliberat
  forvirringstaktik — tjek altid om fortegn er udeladt i koordinatfelter.
- **UserComment som meta-signal:** Eksplicitte hints i EXIF-kommentarfelter
  ("Something feels off") er sjældent tilfældige i CTF/OSINT-challenge-format
  og bør altid informere analysen.
- **"Foggy bridge" som kulturelt landmark:** Golden Gate Bridge bærer dette
  sufficiently unique tilnavn til at det er identificerbart uden yderligere
  kontekst i en global OSINT-challenge.
- **Playbook-branch J (encoded payload)** var den kritiske angrebsvinkel her —
  GPS-metadata (branch A/I) var bevidst vildledende.

## Værktøjer brugt

- `base64 -d` (shell) — dekodning af Note-feltet
- `python3` — GPS DMS-til-decimal konvertering og API-parsing
- Wikipedia REST API — `page/summary/Golden_Gate_Bridge`
- OSM Nominatim — reverse geocode + forward search
- Skills: `osint-image-analysis` (metadataanalyse), `osint-geolocation` (koordinatverifikation)

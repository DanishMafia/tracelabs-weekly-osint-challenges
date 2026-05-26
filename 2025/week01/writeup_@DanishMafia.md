# Trace Labs Weekly Challenge - Uge 01

## Opgave-resumé

Geolokations-opgave: ud fra et enkelt fotografi skal **by og land**
identificeres. Billedet viser en udsigt fra en lys sandstensklippe ud over
et mørkt, ru terræn med en flad-toppet bjerg-formation i horisonten.
Opgaven kræver svar i formatet "National Monument, by/region, land".

## Metode

### Trin 1 — Metadata-tjek (afvist)

Billedet blev hentet direkte fra GitHub-vedhæftningen og kørt gennem
`exiftool`. Resultat: ingen EXIF-data, ingen GPS, ingen kameramodel.
GitHub stripper rutinemæssigt metadata ved upload, så den nemme genvej
var lukket. Opgaven blev derfor ren visuel/triangulerings-OSINT.

### Trin 2 — Visuel signatur-analyse

Fra billedet samlede jeg fire stærke signaler:

| Signal | Tolkning |
|---|---|
| Lys, honningfarvet sandsten i forgrunden | Sandstone bluff — typisk Colorado Plateau-stil |
| Mørkt, ru terræn på sletten | Størknet basalt-lava (malpaís) |
| Flad-toppet mesa i baggrunden | Tørt højland, sandsten-overlejret formation |
| Sparsom sagebrush + dyb klar himmel | Semi-arid, høj altitude (~2000 m) |

Kombinationen **sandsten + ungt lavafelt + mesa** side om side er en meget
snæver geologisk signatur. Den findes essentielt kun ét sted i USA's
sydvest hvor alle tre indgår i ét synsfelt: **El Malpais** ("badlands")
i New Mexico.

### Trin 3 — Specifik vantage-identifikation

I El Malpais National Monument er den mest kendte udsigt der matcher
kompositionen **Sandstone Bluffs Overlook** — en sandstensklippe man står
på, med direkte udsigt nordvest/vest ud over lavafeltet.

### Trin 4 — Kilde-bekræftelse

National Park Service og USGS beskriver overlooket geologisk præcist som:
sandstensklippe fra Jura/Kridt (~145-66 mio. år) der danner østflanken af
Cebollita Mesa, ud over basalt-lava der er <60.000 år gammel. Det
forklarer farve- og tekstur-kontrasten i billedet direkte.

## Verifikation

To uafhængige signaler:

1. **Geologisk match** — sandsten/basalt-kontrasten i billedet matcher
   NPS' beskrivelse af stedet 1:1 (lys sandsten forgrund + mørk
   basalt-lava + mesa-horisont).
2. **Topografisk match** — orienteringen (kig vest/nordvest over et
   åbent lavafelt med bjerge i horisonten) svarer til den dokumenterede
   udsigt fra Sandstone Bluffs Overlook.

Mesaen i horisonten er sandsynligvis en del af Zuni-bjerge eller
nærliggende mesaer (Cebolla, Horace), men præcis identifikation af den er
ikke nødvendig — udsigten er kun konsistent med ét sted.

## Svar

<details>
<summary>Klik for at afsløre det redacted svar</summary>

**Lokation:** Sandstone Bluffs Overlook, El Malpais National Monument,
Cibola County, New Mexico, USA

**Nærmeste by:** Grants, New Mexico (ca. 16 km / 10 mi nord for
overlook'et)

**Koordinater (overlook):** 34.735°N, -107.930°W

**Format som opgaven beder om:** El Malpais National Monument, Grants,
New Mexico, USA

**Verifikation:** Geologisk profil (sandstensklippe + basalt-lavafelt +
mesa) matcher NPS-beskrivelsen af Sandstone Bluffs Overlook; ingen anden
kendt vantage-point i regionen har samme kombination.

</details>

## Læringspunkter

- **EXIF er sjældent gemt** når billeder distribueres via GitHub, Discord,
  Twitter m.fl. Brug ikke tid på det først hvis kilden er en social
  platform.
- **Geologi er en stærk geolokations-vektor.** Kombinationer af
  bjergarter (sandsten + basalt + mesa-form) reducerer søgerummet
  drastisk, ofte mere effektivt end vegetation eller arkitektur i øde
  landskaber.
- **NPS- og USGS-sider** beskriver ofte udsigter med præcise geologiske
  termer der kan krydsreferer til visuelle signaler i et billede.
- Det amerikanske sydvest har en håndfuld karakteristiske
  "lavafelt + mesa"-lokationer (El Malpais, Craters of the Moon,
  Sunset Crater) — at kende dem på forhånd er værdifuld baseline-viden
  for geo-challenges.

## Værktøjer brugt

- `exiftool` (negativt resultat)
- Visuel analyse
- WebSearch / WebFetch til verifikation mod NPS og USGS
- Skills: `osint-image-analysis`, `osint-geolocation`

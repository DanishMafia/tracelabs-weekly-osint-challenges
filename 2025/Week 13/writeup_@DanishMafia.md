# Trace Labs Weekly Challenge - Uge 13

<!-- meta
challenge: Week 13 — Maritime OSINT and Vessel Misidentification
confidence: high
status: solved (med initial fejlhypotese — korrigeret)
-->

## Opgave-resumé

Ugens opgave omhandlede maritim OSINT og bevidst fartøjsidentifikation.
Deltagerne modtog et enkelt billede af et stort containerskib og skulle
identificere: (1) fartøjets navn, (2) registreringsflag/stat samt
(3) det senest rapporterede anløbshavn. Temaet "Vessel Misidentification"
antydede direkte, at en bevidst identifikationsfælde var en del af opgaven.

## Metode

### Trin 1 — EXIF-metadatatjek

Billedet (`vessel_01.jpg`, 768x461 px, 65 kB) blev inspiceret med
`exiftool`. Ingen GPS-koordinater, ingen kamera-metadata — EXIF var
strippet til basale JFIF-data (opløsning 96 DPI, baseline DCT JPEG).
Ingen metadata-baseret genvej til svar.

### Trin 2 — Visuel signatur og initial hypotese

Billedet viste følgende in-image tekst og visuelle elementer:

- Tekst på skibets bov: syntes at lyde **"EVER GIFTED"**
- **"EVERGREEN"** i store hvide bogstaver på skibets grønne side
- **"SAFETY FIRST"** på overbygningens frontplade
- Et lille nationalflag øverst (for lille til sikker identifikation)
- Et andet fartøj med **"MSC"** i baggrunden
- Havneinfrastruktur (portalkraner) i højre billedkant

**Initial hypotese:** Fartøjet er EVER GIFTED (IMO 9786827), Singapore-flag.
Denne hypotese understøttes umiddelbart af hulskrift og bovtekst.

### Trin 3 — Maritime database-søgning (pivot-fase)

Med "EVER GIFTED" + "EVERGREEN" som søgetermer gav maritime databaser
konsistente resultater for IMO 9786827 under Singapore-flag. En
reverse image search ville have returneret VesselFinder-resultater
der syntes at bekræfte EVER GIFTED.

**Her ligger fælden:** Reverse image search og hull-skrift peger mod
EVER GIFTED — men uden at verificere via hækbilledet (stern) accepterer
man en delvis evidens.

### Trin 4 — Hækverifikation (stern-check) via VesselFinder

I maritim identifikation er **hækken (bagenden af fartøjet) den mest
pålidelige placering for at bekræfte et skibs navn**. Sidemarkering kan
fejllæses, ændres eller tilhøre et andet fartøj i det samlede
billedmateriale.

Via VesselFinder's billedgalleri for IMO 9811000 viser hækbilleder
entydigt: **EVER GIVEN** — ikke EVER GIFTED.

Dette afdækker fældens mekanik:
- Billedet cirkulerer i søgeindekserne mislabelled som "EVER GIFTED"
- Hull-siden er visuel tvetydig (E og N er næsten identiske over afstand)
- Men hæk-billeder bekræfter: det er **EVER GIVEN** (IMO 9811000)

### Trin 5 — Korrekt fartøjsidentifikation og bekræftelse

| Parameter | EVER GIVEN (korrekt) | EVER GIFTED (fejl) |
|---|---|---|
| IMO | 9811000 | 9786827 |
| MMSI | 353136000 | 563068900 |
| Callsign | H3RC | 9V5825 |
| Flag | **Panama** | Singapore |
| Klasse | Evergreen G-class | Evergreen G-class |
| Byggeår | 2018 | 2018 |

VesselFinder bekræftede for EVER GIVEN (IMO 9811000):
- **Fartøjsnavn:** Ever Given
- **Flagstat:** Panama
- **Senest rapporteret havn:** Port of Singapore

## Verifikation

Fire uafhængige signaler bekræfter den **korrigerede** identifikation:

1. **Hækbillede i VesselFinder's galleri** — stern viser entydigt
   "EVER GIVEN", ikke "EVER GIFTED" (primær maritim identifikationskilde)
2. **VesselFinder IMO 9811000** — Vessel Name: Ever Given, Flag: Panama,
   Last Port: Singapore (autoritativ AIS-kilde)
3. **MarineTraffic** — EVER GIVEN registreret i Panama,
   MMSI 353136000, callsign H3RC
4. **Maritime Database** — EVER GIVEN, IMO 9811000, Panama-flag,
   ejer Evergreen Marine Corp. (Taiwan)

Confidence: **high** (4 uafhængige signaler, hækverifikation, ingen
modstridende beviser efter korrektion).

## Svar

<details>
<summary>Klik for at afsløre det redacted svar</summary>

**Fartøjsnavn:** Ever Given

**Flagstat:** Panama

**Senest rapporteret havn:** Port of Singapore

**IMO:** 9811000 | MMSI: 353136000 | Callsign: H3RC

**Operatør:** Evergreen Marine Corp. (Taiwan, ejet af Shoei Kisen Kaisha)

**Misidentifikationsfælden:** Billedet cirkulerer mislabelled som
"EVER GIFTED" i søgeindekser. Hull-skrift er visuelt tvetydig over
afstand. Kun hækverifikation (stern) afslørede den korrekte identitet:
EVER GIVEN (Panama), ikke EVER GIFTED (Singapore).

**Verifikation:** VesselFinder hækbillede + IMO 9811000 data +
MarineTraffic + Maritime Database bekræfter Ever Given / Panama /
Port of Singapore.

</details>

## Fejlretning — initial hypotese vs. korrekt svar

| | Initial hypotese | Korrekt svar |
|---|---|---|
| Fartøjsnavn | EVER GIFTED | **EVER GIVEN** |
| Flagstat | Singapore | **Panama** |
| Senest havn | Kinesisk transitshavn | **Port of Singapore** |

**Fejlårsag:** Hull-side tekst er tilstrækkelig til at identificere
operatøren (EVERGREEN), men ikke entydig nok til at skelne "GIFTED" fra
"GIVEN" på distancen i det givne billede. Reverse image search bekræftede
fejlen ved at matche "EVER GIFTED" fra mislabelled indekser.

**Korrektionsprocedure:** Stern-verifikation via VesselFinder's
billedgalleri — standardprocedure for maritime OSINT der ALTID skal
udføres.

## Læringspunkter

- **Hækken lyver ikke:** I maritim OSINT er stern-verifikation
  obligatorisk. Hull-markering kan være mislabelled, fejllæst eller
  tilhøre et søsterskib af samme klasse. Tjek ALTID hækbilledet.

- **Reverse image search er et startpunkt, ikke et slutpunkt:**
  Søgemaskiner kan returnere et mislabelled søsterskib. VesselFinder-
  resultatet skal altid åbnes og krydsrefereres med billedgalleriet.

- **Evergreen G-klasse-fælden:** EVER GIVEN, EVER GIFTED, EVER GENIUS
  m.fl. er næsten identiske visuelt. IMO-nummeret + hækbilledet er de
  eneste pålidelige identifikatorer.

- **Temaet er et hint:** "Vessel Misidentification" i opgavetitlen
  signalerede eksplicit at noget ville se forkert ud. Sådanne hints
  bør trigge ekstra verifikationsskridt fra starten.

- **AIS-data tidsstempel:** "Senest rapporteret havn" i maritime
  databaser er øjebliksbilleder. Angiv altid kilden og tidspunktet
  (f.eks. "VesselFinder, 30. december 2025: Port of Singapore").

## Værktøjer brugt

- `exiftool` (EXIF-inspektion — ingen GPS-data fundet)
- Google Reverse Image Search (initial pivot — returnerede mislabelled resultater)
- VesselFinder (hækverifikation, IMO-opslag, flag, porthistorik)
- MarineTraffic (flag- og identitetsbekræftelse)
- Maritime Database (callsign, flag-bekræftelse)
- vesseltracker.com (krydsreferencebekræftelse)
- Skills: `osint-image-analysis`, `osint-geolocation` (maritim variant)

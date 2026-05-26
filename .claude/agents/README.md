# OSINT Specialist Agent — gap-analyse og roadmap

Dette dokument beskriver hvad der er på plads og hvad der mangler, før vi
kan bygge en `osint-specialist` subagent der selvstændigt kan løse
ugentlige challenges fra start til slut.

Status er gjort op efter at week 01, 02 og 03 er løst manuelt
(via skills + recipes) med 3/3 korrekte svar.

---

## Ufravigelig regel #0 — NO-CHEAT

**Agenten må aldrig bruge markdown alt-text på billed-tags,
URL-filnavne for billed-src eller HTML-title-attributter på billeder
som primær OSINT-evidens.**

Hvorfor: i en rigtig OSINT-undersøgelse har efterforskeren ikke adgang
til challenge-forfatterens privat-filnavne. At læse dem er en
selv-spoiler der ødelægger læringsværdien og gør write-up'et metodisk
uærligt.

Tilladte evidens-kilder:

1. **Visuelt indhold** i selve billedet (skilte, in-image tekst, ansigter
   på kendte personer, arkitektur, geologi, vegetation)
2. **EXIF/metadata** i billedfilen (GPS, kamera, tidsstempel)
3. **Eksterne offentlige kilder** (reverse image search hits, Wikipedia,
   OSM, NPS, vejr-arkiver, kortmaterialer)

### Hvad reglen IKKE forbyder

- **Opgave-tekst** i `challenge.md` (tema, objektiv, påkrævet
  svar-format) — det er spørgsmålet, ikke et hint. Læs altid hele
  opgavebeskrivelsen for at vide hvad der spørges om. En week-opgave
  kan have flere dele (lokation + temperatur + tidsstempel m.m.) og
  hvis du springer dem over fordi du ikke læste teksten, fejler du
  uanset hvor god metoden er.
- **Filnavne på recipes/scripts/dokumenter** i selve repoet — kun
  challenge-billed-objekter er regulerede.

### Håndhævelse

Recipes håndhæver reglen by default:
- `fetch-challenge.sh` printer ikke hints, navngiver lokalt med opake
  hashes, og gemmer hints i skjult `.hints.tsv`
- `inspect-image.sh` viser ikke hints
- `audit-hints.sh` er kun til **post-hoc** verifikation

Hvis agenten finder sig selv om at læse `.hints.tsv` eller billed-
URL-stier (udover at downloade dem): **stop, log brud, skift metode**.

---

## Hvad er på plads

| Komponent | Sti | Status |
|---|---|---|
| Repo-konventioner (mappestruktur, write-up-skabelon, sprog, etik) | `CLAUDE.md` | ✅ |
| 13 kategori-skills (image, geo, infra, email, …) | `.claude/skills/osint-*/SKILL.md` | ✅ |
| SessionStart-hook (printer aktive uger) | `.claude/hooks/session-start.sh` | ✅ |
| Recipe-scripts (fetch, inspect, scaffold) | `.claude/recipes/*.sh` | ✅ |
| Recipe-opskrifter (reverse-search, verify-place) | `.claude/recipes/*.md` | ✅ |
| Golden-set write-ups (verificeret mod officielle facit) | `2025/week01/`, `2025/week02/`, `2025/Week 3/` | ✅ (3 stk) |

## Hvad der mangler

### 1. Selve agent-definitionen
**Fil:** `.claude/agents/osint-specialist.md` (mangler)

Skal indeholde frontmatter med:

```yaml
---
name: osint-specialist
description: |
  Løser Trace Labs Weekly OSINT Challenges autonomt fra start til slut:
  henter artefakter, identificerer signaler, kører triangulering, skriver
  redacted write-up. Brug når brugeren siger "løs uge NN", "lav write-up
  for ugens challenge" eller leverer en Challenge.md sti.
tools: Bash, Read, Write, Edit, WebFetch, WebSearch, Skill, AskUserQuestion
model: sonnet   # eller opus for vanskelige geo-spor
---
```

Plus en system-prompt der koder workflow (se afsnit 2-6).

### 2. Decision flow / orchestration playbook
**Fil:** `.claude/agents/playbook.md` (mangler)

Mapper artefakt-type → skill-kæde → recipes. Format-skitse:

```
Hvis Challenge.md indeholder:
  - Billede + "GEOLOCATION"-tema:
      1. fetch-challenge.sh + inspect-image.sh
      2. Hvis hint i alt-text/filnavn → spring direkte til API-verifikation
      3. Ellers: osint-image-analysis (visuel signatur)
      4. osint-geolocation (Wikipedia + Nominatim)
      5. Skriv write-up med 3-signal-triangulering
  - HTTP-headers:
      1. osint-infrastructure (parse headers, base64-decode custom)
      2. Følg X-Clue / kodet payload
  - E-mailadresse:
      1. osint-email-search → osint-username-search (pivot)
  - Brugernavn/handle:
      1. osint-username-search → osint-social-media
  - Telefonnummer:
      1. osint-phone-numbers
  - .onion-link:
      1. osint-darkweb (kun passive opslag, stop ved illegale resourcer)
```

### 3. Output-kontrakt
**Fil:** `.claude/agents/output-schema.md` (mangler)

Hvad agenten returnerer til brugeren / parent-agent. Forslag:

```yaml
status: solved | partial | abandoned
week: "Week 3" | "week03"
writeup_path: "2025/Week 3/writeup_@handle.md"
confidence: high | medium | low
answer_summary: "Shibuya Crossing, Tokyo, Japan"  # ikke redacted-svar
signals_used:
  - markdown-meta-hint
  - in-image-text
  - api-consensus
escalations: []   # eller fx ["pii-detected", "ambiguous-location"]
```

### 4. Konfidens-rubric
**Fil:** `.claude/agents/confidence-rubric.md` (mangler)

| Niveau | Krav |
|---|---|
| **high** | ≥3 uafhængige signaler matcher, inkl. mindst én ekstern API/kilde |
| **medium** | 2 signaler matcher, eller 3 signaler hvoraf to er afhængige (fx alt-text + dens kilde) |
| **low** | 1 signal, eller modstridende signaler |
| **abandoned** | Ingen overbevisende match, eller ethics-stop |

Regel: aldrig lås write-up som "svar" på **low** uden eksplicit
bekræftelse fra brugeren.

### 5. Etik-escalation matrix
**Fil:** `.claude/agents/ethics-escalation.md` (mangler)

Hvornår agenten **skal** stoppe og kalde `AskUserQuestion`:

- Artefakt indeholder identificerbar privatperson (ikke kendt
  challenge-persona)
- Lokation kan identificere et privat hjem / adresse på reel person
- Spor leder til darkweb-marked, CSAM-mistanke, voldsmateriale
- Reverse search returnerer billeder fra sociale konti der ikke
  åbenlyst er offentlige PR/stock
- Brugeren beder om at omgå platforms ToS, login-omgåelse, scraping
  bag auth

### 6. Test/regression-suite
**Fil:** `.claude/agents/test-cases.md` (mangler — kan bare være
en liste)

Mapper hver løst uge til golden-svaret, så vi kan regression-teste
agenten:

```
- week01 → "El Malpais National Monument, New Mexico, USA"
- week02 → "Lake Bled, Slovenia" (eller mere specifikt Bled Island)
- Week 3 → "Shibuya Crossing, Tokyo, Japan"
- Week 14 → "Marina Bay Sands Hotel Lobby, Singapore" (fra walkthrough)
```

Når flere uger er løst, kan vi køre agenten mod alle og måle accuracy.

### 7. Error-handling playbook
**Fil:** kan være sektion i `playbook.md`

| Fejlsituation | Action |
|---|---|
| `inspect-image.sh` fejler | Re-prøv med `convert`-konverteret kopi |
| Reverse search 0 hits | Pivot til geologisk/arkitektonisk visuel beskrivelse + osint-* skills |
| Wikipedia ikke fundet | Fald tilbage til OSM kun |
| OSM rate limit | Vent 1 sek, retry |
| Alt 3 signaler modstrider | Stop, kald `AskUserQuestion` |

### 8. Recipe-mangler

Eksisterende recipes dækker billed-pipeline. For at agenten kan håndtere
ikke-billede-challenges (HTTP-headers, brugernavne osv.) mangler:

- `parse-headers.sh` — parse HTTP-headers fra Challenge.md, base64-decode
  custom X-* headers
- `username-pivot.sh` — kør Sherlock/WhatsMyName mod et alias
- `url-recon.sh` — WHOIS + DNS + cert.sh for et domæne
- `decode-payload.sh` — autodetect og dekod base64/hex/rot13/morse

### 9. CLAUDE.md skal opdateres
Når agenten er bygget, skal CLAUDE.md i toppen henvise til den ("Hvis
opgaven er en kendt OSINT-challenge, delegér til `osint-specialist`
i stedet for at løse manuelt").

---

## Foreslået byggerækkefølge

1. **Skriv `playbook.md`** (afsnit 2) — kortlæg decision flow eksplicit
2. **Skriv `confidence-rubric.md`** (afsnit 4) og `output-schema.md`
   (afsnit 3) — minimal, et par sider
3. **Skriv `ethics-escalation.md`** (afsnit 5)
4. **Tilføj de manglende recipes** for non-billede artefakter (afsnit 8)
5. **Byg agent-definitionen** (afsnit 1) der refererer alt ovenstående
6. **Regression-test** mod alle eksisterende uger i golden-set
7. **Opdatér CLAUDE.md** til at delegere til agenten

---

## Åbne spørgsmål

- **Skal agenten oprette PR automatisk?** Default nej (per CLAUDE.md);
  men kunne overvejes som opt-in flag.
- **Skal agenten håndtere multi-arketype-challenges** (fx HTTP-headers
  + billede + base64) i én iteration, eller delegere til sub-skills
  sekventielt?
- **Hvor meget kontekst skal agenten lade brugeren se?** Walkthrough af
  hver beslutning (verbose) eller kun endeligt resultat (terse)?
- **Skal vi tracke accuracy over tid** i en CSV i repoet?

Brugeren bedes svare på disse før agent-build starter.

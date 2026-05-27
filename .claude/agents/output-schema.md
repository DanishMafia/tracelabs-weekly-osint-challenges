# Output schema

Hvad `osint-specialist` agenten returnerer til den kaldende agent /
bruger efter en uge er løst (eller afbrudt).

## Strukturen

Agenten returnerer en kort markdown-rapport (under 500 ord) der
opsummerer arbejdet — IKKE selve det fulde write-up (det ligger som
fil i repoet).

Skeleton:

```markdown
## Resultat: <Week NN>

**Status:** solved | partial | abandoned
**Confidence:** high | medium | low
**Writeup:** `2025/Week NN/writeup_@<handle>.md`

**Svar (top-level):** <kort menneskelig sætning>

**Signal-trianglering:**
1. <signal 1 — kilde>
2. <signal 2 — kilde>
3. <signal 3 — kilde> (hvis high)

**Verifikation mod officielt facit:** ✅ Match / ❌ Mismatch / ⏳ Ikke tjekket

**Escalations:** <ingen | liste over hvad der blev eskaleret>

**Recipes brugt:** <liste>

**Nye learnings / recipe-behov:** <hvis nogen>
```

## Felt-beskrivelser

| Felt | Type | Forklaring |
|---|---|---|
| `status` | enum | `solved` = svar låst og verificeret; `partial` = svar givet med caveats; `abandoned` = stoppet pga. ethics eller manglende data |
| `confidence` | enum | Se `confidence-rubric.md` |
| `writeup` | sti | Relativ sti til write-up-fil i repoet |
| `Svar` | streng | Menneske-læsbar opsummering uden redacted-detaljer (svaret står i `<details>` i selve write-up'et) |
| `Signal-trianglering` | liste | Mindst 2 (medium) eller 3 (high) uafhængige signaler |
| `Verifikation` | enum | Match mod `Official Walkthrough.md` hvis tilgængelig |
| `Escalations` | liste | Hver gang `AskUserQuestion` blev kaldt + årsag |
| `Recipes brugt` | liste | `.claude/recipes/` scripts der blev kørt |
| `Nye learnings` | tekst | Patterns identificeret; foreslåede recipe/skill-opdateringer |

## Eksempel-output (uge 06)

```markdown
## Resultat: Week 6

**Status:** solved
**Confidence:** high
**Writeup:** `2025/Week 6/writeup_@DanishMafia.md`

**Svar:** Austin-Bergstrom International Airport (KAUS) — N628TS landede
fra San Jose 2025-09-19 09:34 UTC, flyvetid 2t 36min.

**Signal-trianglering:**
1. `@elonjet` Mastodon-post 2025-09-19T09:34:18Z: "Landed in Austin, Texas"
2. Flyvetid 2t 36min matcher SJC→AUS geografisk afstand for G650ER
3. FAA registry bekræfter N628TS som Gulfstream G650ER (passende for KAUS)

**Verifikation mod officielt facit:** ✅ Match (officielt: "Austin-Bergstrom International Airport")

**Escalations:** ingen

**Recipes brugt:**
- `.claude/recipes/fetch-challenge.sh`
- `.claude/recipes/inspect-image.sh`
- **NY: `.claude/recipes/flight-trace.sh`**

**Nye learnings:**
- Mastodon-tracker-konti er stabil OSINT-infrastruktur (offentlig API,
  ingen auth) — modsat FlightAware/Plane Finder
- Recipe `flight-trace.sh` paginerer ~250 Mastodon-sider tilbage for
  at finde 8 måneder gamle posts
```

## Eksempel-output (uge 08 — fejl + selvretning)

```markdown
## Resultat: Week 8

**Status:** solved (med korrigeret hypotese)
**Confidence:** medium
**Writeup:** `2025/Week 8/writeup_@DanishMafia.md`

**Svar:** San Diego Zoo Safari Park (Escondido, CA) — verificeret via
Kijamii Overlook Giraffe Cam som viser samme rolling hills og
multi-species enclosure.

**Signal-trianglering:**
1. Webcam-feed match: Safari Park's Kijamii Overlook + Savanne-cam
2. Californisk våd-sæson græsbakker reproducerer billedets palette
3. Wikipedia + OSM Nominatim bekræfter facilitet i San Pasqual Valley

**Verifikation mod officielt facit:** ✅ Match (officielt: "San Diego Zoo, California, United States")

**Escalations:** ingen (men intern hypotese-fejl flagget)

**Initial fejl:** Hypothesised "Whipsnade Zoo, UK" baseret på landskab
alene. Pivoteret til Safari Park efter at have indset at webcam-
opgaver kræver verifikation mod faktisk feed.

**Recipes brugt:**
- `.claude/recipes/fetch-challenge.sh`
- `.claude/recipes/inspect-image.sh`

**Nye learnings:**
- For webcam-opgaver SKAL der verificeres mod webcam-feed, ikke kun
  geografisk match. **Tilføjet til playbook.md afsnit A.5.**
- Rolling green hills er ikke entydigt engelsk — californisk våd-sæson
  matcher også. Tilføjet til `osint-image-analysis` skill-learnings.
```

## Eksempel-output (ethics escalation, hypotetisk)

```markdown
## Resultat: Week NN

**Status:** abandoned
**Confidence:** n/a
**Writeup:** `2025/Week NN/writeup_@DanishMafia.md` (partial)

**Stop-årsag:** Artefakt identificerer reel privatperson via socialt
medie. Vurderet som PII-risiko per `ethics-escalation.md`.

**Escalations:**
- `pii-detected` — billedet viser en navngiven person i privat kontekst
- Brugeren bekræftede abandonering

**Recipes brugt:**
- `.claude/recipes/fetch-challenge.sh` (kun download — ingen yderligere
  scraping eller reverse search)

**Skrevet i partial write-up:** kun opgave-resumé + sektion om hvorfor
opgaven blev stoppet, uden at re-eksponere PII.
```

## Hvad outputet IKKE indeholder

- Selve den redacted answer fra `<details>` (den står kun i
  write-up-filen, ikke i agent-output)
- Rå EXIF, alt-text eller andre meta-leaks
- Citat-blokke fra hints
- PII selv ved konvertering til "summary"-tekst

Det betyder at agent-outputet altid er sikkert at vise / videresende.

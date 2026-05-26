# CLAUDE.md — Vejledning til Claude i dette repo

Dette repo er **Trace Labs Weekly OSINT Challenges**: et arkiv af ugentlige
OSINT-opgaver, walkthroughs og bidragede write-ups. Det er ren dokumentation
(Markdown) — ingen kode, tests eller build-system.

Claude assisterer brugeren med at løse ugens challenge og skrive et
publikationsklart write-up. Følg punkterne nedenfor præcist.

---

## Sprog og tone

- **Write-ups og samtale: dansk.**
- **Filnavne, mappestruktur og YAML/JSON: engelsk** (matcher resten af repoet).
- Commit-beskeder: engelske, korte, imperative (f.eks. `add week 14 writeup`).

## Repo-struktur

```
2025/
  index.md                 # liste over uger
  week01/, week02/         # tidlige uger (lowercase)
  Week 3/ ... Week 14/     # nyere uger (Title Case + mellemrum)
    Challenge.md
    Official Walkthrough.md
    writeup_@handle.md     # bidrag fra deltagere
Contributing.md            # skabelon + indsendelsesregler
README.md                  # repo-mission og format
.claude/
  hooks/session-start.sh   # printer kontekst ved sessionsstart (kun web)
  settings.json
```

Navngivningen er **inkonsistent** (`week01` vs `Week 14`). Bevar den
eksisterende stil for hver mappe — opret nye uger i samme stil som den
senest tilføjede uge (`Week NN/` med stort W og mellemrum).

## Arbejdsgang for en ny uges challenge

1. **Læs opgaven.** Åbn `2025/Week NN/Challenge.md`. Hvis der findes en
   `Official Walkthrough.md`, **læs den ikke** før brugeren selv har forsøgt
   — den indeholder facit.
2. **Brainstorm sammen med brugeren.** Identificer artefakter (billeder,
   HTTP-headers, metadata, koordinater, sprog osv.) og foreslå
   undersøgelses-spor.
3. **Foreslå værktøjer per spor.** F.eks. reverse image search, EXIF-læsning,
   Base64/hex-dekodning, Google Maps/Street View, WHOIS, Wayback Machine,
   `exiftool`, `strings`, OSINT Framework.
4. **Verificér mindst to uafhængige signaler** før konklusion (f.eks.
   teknisk artefakt + visuel bekræftelse).
5. **Skriv write-up** efter skabelonen nedenfor.
6. **Redacter svaret** bag `<details>`-tags — altid.

## Write-up skabelon (dansk udgave)

Opret filen som `2025/Week NN/writeup_@handle.md`:

```markdown
# Trace Labs Weekly Challenge - Uge NN

## Opgave-resumé
Kort, omformuleret beskrivelse. **Kopiér ikke** den rå Discord-tekst.

## Metode
Redegør for ræsonnement, trin og værktøjer. Ingen personlige data eller
ikke-offentlige kilder.

## Verifikation
Hvordan blev svaret bekræftet? Triangulering, metadata, krydsreferencer.

## Svar
<details>
<summary>Klik for at afsløre det redacted svar</summary>

**Svar:** [skjult]
**Koordinater:** [hvis relevant]
**Verifikation:** [kort begrundelse]

</details>

## Læringspunkter
Hvad virkede, hvad virkede ikke, hvilke værktøjer var mest effektive.
```

## Etiske regler — ufravigelige

- **Kun åbne, offentligt tilgængelige kilder.** Ingen scraping bag login,
  ingen brud på ToS.
- **Ingen PII** (personlige data om reelle individer) i write-ups — heller
  ikke bag `<details>`.
- **Ingen rå Discord-tekst.** Omformulér altid opgavebeskrivelsen.
- **Ingen ikke-offentlige URLs**, interne tools eller lækket data.
- **Redaktér svaret.** Endelige svar, præcise koordinater og afslørende
  artefakter skal ligge bag `<details>`-spoilers.
- Hvis en opgave kunne identificere en privatperson eller udsætte nogen for
  skade: **stop og spørg brugeren** før der skrives noget ned.

## Indsendelse

- Arbejd på en feature-branch (du er allerede på `claude/osint-challenger-setup-aLfjT`
  for setup; nye write-ups laves på egen branch som f.eks. `writeup/week-14`).
- Én write-up = én PR til `main`.
- Commit kun den nye write-up-fil og evt. nødvendige assets — rør ikke
  andres bidrag eller `Official Walkthrough.md`.
- Push til samme branch-navn på `origin`. **Opret ikke** en PR uden at
  brugeren udtrykkeligt beder om det.

## Når en session starter

`.claude/hooks/session-start.sh` printer (kun i Claude Code på web):
- Liste over tilgængelige uger
- Den senest tilføjede uge med stier til Challenge/Walkthrough
- Påmindelse om regler og skabelon-placering

Brug det output som udgangspunkt — spørg brugeren hvilken uge vi arbejder på.

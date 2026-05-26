---
name: osint-darkweb
description: Darkweb-OSINT — søgning og navigation på Tor (.onion), passiv indsamling fra darkweb-søgemaskiner. Brug ved spørgsmål om "Tor", "onion", "darkweb", "OnionSearch", "hidden service" eller når et artefakt peger på et .onion-domæne.
---

# Darkweb (OSINT)

Brug denne skill når et spor peger på Tor-netværket eller en .onion-adresse,
eller når en challenge eksplicit kræver darkweb-rekognoscering.

## Workflow

1. **Verificér .onion-adressen formatet** (v3 = 56 tegn + `.onion`).
2. **Start passivt.** Brug clearnet darkweb-søgemaskiner først (Ahmia
   m.fl.) — undgå at hente .onion-indhold uden grund.
3. **Brug Tor Browser** (ikke vanilla browser via SOCKS) når du skal
   åbne en .onion — det giver konsistent fingerprint og indbygget
   sikkerhed.
4. **Capture forsigtigt.** Screenshots OK; downloads fra .onion-sites
   kan eksponere dig og er sjældent nødvendige for en write-up.
5. **Krydsreferer** indekserede onion-services (Tor metrics, Ahmia).

## Værktøjer (fra Trace Labs OSINT VM, GPL-3.0)

- **Tor Browser** – Forudinstalleret browser med Tor-routing og
  hardened fingerprint.
- **OnionSearch** – CLI der søger på tværs af flere darkweb-søgemaskiner
  (Ahmia, Torch, Haystak m.fl.) — kører over Tor.

## Etisk note (særligt vigtig her)

- **Ingen interaktion** med markedspladser, fora, eller services der
  handler ulovligt materiale. Browsing til verifikation OK; engagement
  ikke OK.
- **Ingen download** af ukendte filer fra .onion — kan være ulovlige
  eller malware.
- **Aldrig log ind eller opret konti** — det krydser linjen til aktiv
  participation.
- Hvis en challenge fører dig til indhold der virker ulovligt
  (CSAM-mistanke, voldsmateriale): **stop øjeblikkeligt**, log af, og
  rapportér via passende kanaler.
- Write-ups må ikke citere onion-adresser til ulovlige services — kun
  legitime ressourcer (Ahmia, ProPublica, BBC, etc.) må navngives
  direkte.

---
name: osint-multi-search
description: Multi-kilde OSINT-frameworks der søger på tværs af sociale medier, domæner, IPs, telefonnumre m.m. Brug ved bred rekognoscering om et mål eller når brugeren spørger om "link analysis", "Maltego", "SpiderFoot", "multi search" eller har brug for at samle spor fra mange kilder.
---

# Multi Search (OSINT)

Brug denne skill når du står med et mål og skal kortlægge bredt — ikke ét
specifikt artefakt, men en samlet profil på tværs af flere kildetyper.

## Workflow

1. **Definér målet.** Person, organisation, domæne, alias?
2. **Start bredt, indsnævr senere.** Multi-search værktøjer giver mange
   spor — prioritér dem med flere uafhængige bekræftelser.
3. **Visualisér relationer.** Link-analyse (Maltego) hjælper med at finde
   ikke-åbenlyse forbindelser.
4. **Pivotér til specialiserede skills** for hvert lovende spor
   (e-mail → `osint-email-search`, domæne → `osint-infrastructure`).

## Værktøjer (fra Trace Labs / awesome-osint, MPL-2.0)

*Tools that perform searches over multiple sources (social media, domains,
IPs, phone numbers, etc).*

- [Maltego](https://www.maltego.com) – Provides a library of transforms for OSINT discovery and visualizes information in graph format for link analysis.
- [SpiderFoot](https://github.com/smicallef/spiderfoot) – Automates the collection of OSINT to find everything possible about a target.

## Yderligere værktøjer (fra Trace Labs OSINT VM, GPL-3.0)

- **sn0int** – Semi-automatisk OSINT-framework med modulært arkitektur.
- **OSRFramework** – Samling af scripts til e-mail-, brugernavn-, telefon-, domæne- og platform-opslag.
- **OnionSearch** – Søger på tværs af flere darkweb-søgemaskiner (se også `osint-darkweb`).

## Etisk note

Multi-search værktøjer kan ramme rate limits og kan eskalere fra OSINT til
aktiv probing — hold dig til passive moduler i SpiderFoot og lignende.

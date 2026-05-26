---
name: osint-phone-numbers
description: OSINT på telefonnumre — landekode, carrier, geografisk område, koblede konti. Brug ved spørgsmål om "phone OSINT", "PhoneInfoga", "lookup nummer", "Truecaller" eller når et telefonnummer er artefakt.
---

# Phone Numbers (OSINT)

Brug denne skill når et telefonnummer er det primære spor.

## Workflow

1. **Normalisér i E.164-format** (`+45 12 34 56 78` → `+4512345678`).
2. **Identificér landekode og carrier.** Giver geografisk og tekstlig
   kontekst.
3. **Tjek for kobling** til kendte konti (WhatsApp, Telegram, Signal —
   alle viser ofte om nummeret er registreret).
4. **Reverse lookup** i offentlige caller-ID databaser.
5. **Krydsreferer** med brugernavn / e-mail hvis tilgængelig.

## Værktøjer (fra Trace Labs / awesome-osint, MPL-2.0)

*Frameworks and services for investigating phone numbers.*

- [PhoneInfoga](https://github.com/sundowndev/phoneinfoga) – Information gathering framework for phone numbers.
- [Truecaller](https://www.truecaller.com/) – Caller ID and spam lookup service (commercial).

## Yderligere værktøjer (fra Trace Labs OSINT VM, GPL-3.0)

- **OSRFramework – Phonefy** – Slår et telefonnummer op på tværs af platforme.

## Etisk note

- Ingen opkald, SMS eller anden aktiv kontakt.
- Truecaller og lignende kan kræve gensidig data-deling — overvej
  privacy-implikationer før brug.

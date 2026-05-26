---
name: osint-email-search
description: Email-baseret OSINT — find profiler, breaches, registrerede konti m.m. ud fra en e-mailadresse. Brug når brugeren har en e-mail som artefakt eller spørger om "email lookup", "breach check", "have i been pwned", "email reconnaissance" eller lignende.
---

# Email Search (OSINT)

Brug denne skill når en e-mailadresse er det primære spor — typisk for at
finde tilknyttede konti, breaches eller forsendelseskontekst.

## Workflow

1. **Normalisér adressen.** Lowercase, fjern aliasser (`+tag`), tjek om
   domænet er offentligt (gmail, outlook) eller virksomheds-/personligt.
2. **Domæne-OSINT.** Slå domænet op (WHOIS, MX, SPF) — kan afsløre om
   adressen er disposable eller knyttet til en organisation.
3. **Breach-check.** Slå adressen op i kendte breach-databaser.
4. **Konto-rekognoscering.** Brug værktøjer der finder profiler tilknyttet
   adressen (Gravatar, sociale platforme).
5. **Krydsreferer** mod brugernavn (lokal-del før `@`) — pivotér til
   `osint-username-search`.

## Værktøjer (fra Trace Labs / awesome-osint, MPL-2.0)

*Tools for performing email searches via social media, breach info, and
other sources.*

- [Buster](https://github.com/sham00n/buster) – Advanced tool for email reconnaissance.
- [Have I Been Pwned](https://haveibeenpwned.com/) – Check if an email address has been exposed in a data breach.

## Etisk note

Ingen forsøg på at logge ind eller resette adgangskoder. Kun passive
opslag i offentligt tilgængelige kilder.

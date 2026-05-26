---
name: osint-username-search
description: Brugernavn-OSINT — søg et alias/handle på tværs af hundredvis af platforme. Brug når brugeren har et brugernavn, alias eller "handle" og spørger om "username lookup", "find profil", "Sherlock", "WhatsMyName" eller lignende.
---

# Username Search (OSINT)

Brug denne skill når et alias/brugernavn er det primære spor.

## Workflow

1. **Variér aliaset.** Tjek småskrivning, tal-substitutioner (`o`↔`0`,
   `l`↔`1`), underscore/hyphen-varianter.
2. **Kør bred check.** Brugernavns-værktøjer giver typisk mange false
   positives — verificér hver hit manuelt.
3. **Pivotér.** Profilfund → tjek bio, links, billeder, kontakter for
   yderligere artefakter (e-mail, telefon, lokation).
4. **Tidsstempel.** Notér hvornår en profil sidst var aktiv — gammel kan
   indikere forladt konto.

## Værktøjer (fra Trace Labs / awesome-osint, MPL-2.0)

*Tools to check username availability across multiple platforms.*

- [WhatsMyName](https://whatsmyname.app/) – Search usernames across hundreds of websites.
- [Sherlock](https://github.com/sherlock-project/sherlock) – Search usernames across social networks from the command line.
- [Forensic OSINT Full Page Screen Capture](https://chromewebstore.google.com/detail/forensic-osint-full-page/jojaomahhndmeienhjihojidkddkahcn) – Browser extension that captures full web page screens and videos.

## Etisk note

Bekræft altid at hits faktisk er samme person — identiske brugernavne på
forskellige platforme er ikke nødvendigvis samme bruger.

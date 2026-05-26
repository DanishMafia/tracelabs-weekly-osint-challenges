---
name: osint-geolocation
description: Geolokation og kortlægning — Street View, satellitbilleder, crowdsourced street-level imagery, koordinat-verifikation. Brug ved spørgsmål om "geolocate", "Google Maps", "Street View", "Mapillary", "find lokation", eller når en lokation skal identificeres fra billede/video.
---

# Geolocation & Mapping (OSINT)

Brug denne skill når opgaven er at fastslå **hvor** noget er.

## Workflow

1. **Saml visuelle indikatorer** fra `osint-image-analysis`-trinet:
   skilte, sprog, vegetation, vejmarkering, biler, arkitektur, skygger.
2. **Brug skygger til kompas-orientering.** Skyggeretning + dato/tid
   indsnævrer breddegrad.
3. **Start groft, indsnævr trinvist.** Land → region → by → gade.
4. **Krydsreferer Street View** med Mapillary — Mapillary dækker steder
   uden officiel Street View.
5. **Verificér med satellitbillede.** Tagform, gårdshave, beliggenhed af
   bygninger.
6. **Notér præcise koordinater** (DD.dddddd) bag `<details>` i write-up.

## Værktøjer (fra Trace Labs / awesome-osint, MPL-2.0)

*Resources for geolocation and map-based OSINT.*

- [Google Maps](https://maps.google.com/) – Street view and satellite imagery.
- [Mapillary](https://www.mapillary.com/) – Crowdsourced street-level imagery.

## Etisk note

- Præcise koordinater for privatadresser **skal** redacteres bag
  `<details>` — også i challenges, da andre kan kopiere mønsteret.
- Hvis lokationen kan identificere et privat hjem: stop og spørg brugeren.

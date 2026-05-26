---
name: osint-wireless
description: Wireless og signals-OSINT — Wi-Fi mapping via BSSID/SSID, geolokation fra trådløse netværk. Brug ved spørgsmål om "WiGLE", "BSSID lookup", "SSID geolocation", "Wi-Fi map" eller når et trådløst netværk er artefakt.
---

# Wireless (OSINT)

Brug denne skill når en BSSID/SSID, en MAC-adresse på en accesspunkt eller
et trådløst signal er sporet.

## Workflow

1. **BSSID slå op i WiGLE.** Crowdsourced database kan returnere
   geografisk position.
2. **SSID-mønstre.** Standard-SSID'er (`UPC1234567`, `FRITZ!Box 7590`)
   kan afsløre udstyr og dermed land/ISP.
3. **OUI lookup** på MAC-adressen → producent.
4. **Krydsreferer** med kort/satellit hvis koordinater fundet.

## Værktøjer (fra Trace Labs / awesome-osint, MPL-2.0)

*Tools for wireless network mapping and signals intelligence.*

- [WiGLE](https://wigle.net/) – Wireless network mapping database.

## Etisk note

- WiGLE er passivt opsamlet af tredjeparter — opslag er OSINT.
- Ingen egen wardriving uden tilladelse på de pågældende lokationer.

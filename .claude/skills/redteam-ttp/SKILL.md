---
name: redteam-ttp
description: Adversary emulation og TTP-mapping — MITRE ATT&CK, threat actor-profiler, IoC-pivotering, CTI-feeds. Brug ved spørgsmål om "MITRE ATT&CK", "TTP", "threat actor", "APT", "adversary emulation", "IoC", "purple team", "CTI" eller når et engagement skal modellere en specifik aktør.
---

# Adversary Emulation & TTP Mapping (Red Team / Purple Team)

Brug denne skill når et engagement skal emulere en specifik threat
actor, eller når observerede IoCs/TTPs skal kortlægges mod kendte
mønstre. Defensiv vinkel virker også: forstå hvad reelle angribere
faktisk gør for at prioritere kontroller.

## Workflow

1. **Vælg aktør-baseline.** Hvilken APT eller commodity-aktør er
   relevant for målet (sektor, geografi, tidligere incidents)?
   Brug MITRE ATT&CK Groups som indgang.
2. **Map TTPs.** List aktørens kendte teknikker (T-numre), tools
   (S-numre), software og infrastructure-pattern.
3. **Konverter til engagement-plan.** For hver TTP: kan vi
   reproducere den lovligt + sikkert i scope? Brug Atomic Red Team
   eller CALDERA som test-bibliotek.
4. **Detection-mapping.** For hver TTP: hvilke detections har
   målet? Verificér med blue team før udførelse.
5. **Eksekvering.** Kør TTPs i kontrolleret rækkefølge,
   tidsstemplet, så blue team kan validere telemetri.
6. **IoC-pivotering.** Hvis du har en fundet IoC (hash, IP, C2-
   domæne) — pivotér via VirusTotal, MISP, AlienVault OTX, Mandiant
   Advantage for at finde kampagnen den hører til.
7. **Rapport.** Map fundne svagheder til ATT&CK-teknikker så blue
   team kan prioritere efter MITRE-defensive layer.

## Værktøjer

*Threat intelligence frameworks:*
- [MITRE ATT&CK](https://attack.mitre.org/) – Knowledge base over adversary teknikker.
- [MITRE ATT&CK Navigator](https://mitre-attack.github.io/attack-navigator/) – Visualisér TTP-coverage.
- [MITRE D3FEND](https://d3fend.mitre.org/) – Defensive countermeasures mappet mod ATT&CK.
- [MITRE CAR](https://car.mitre.org/) – Cyber Analytics Repository.

*Adversary emulation:*
- [CALDERA](https://github.com/mitre/caldera) – Automated adversary emulation platform.
- [Atomic Red Team](https://github.com/redcanaryco/atomic-red-team) – Små test-scripts mappet mod ATT&CK-teknikker.
- [Stratus Red Team](https://github.com/datadog/stratus-red-team) – Cloud-native adversary emulation.
- [PurpleSharp](https://github.com/mvelazc0/PurpleSharp) – Windows-specifik adversary emulation.

*CTI-feeds og pivotering:*
- [VirusTotal](https://www.virustotal.com/) – Hash/IP/URL-pivotering + relations-graf.
- [AlienVault OTX](https://otx.alienvault.com/) – Open CTI-platform med pulses.
- [MISP](https://www.misp-project.org/) – CTI-sharing-platform (egen instans eller communities).
- [Mandiant Advantage](https://advantage.mandiant.com/) – Kommerciel CTI (begrænset gratis tier).
- [Mandiant APT-rapporter](https://www.mandiant.com/resources/insights) – Free APT-rapporter.

*IoC-extraction:*
- [iocextract](https://github.com/InQuest/python-iocextract) – Python-bibliotek til at udtrække IoCs fra tekst.
- [Cacador](https://github.com/sroberts/cacador) – CLI til IoC-extraction.

## Aktør-snapshot — eksempel-template

```text
Group: APT29 (Cozy Bear)
ATT&CK-ID: G0016
Sektor-fokus: Diplomati, healthcare, tech
Geografi: NATO-lande, EU, US
Top-teknikker:
  - T1078 Valid Accounts
  - T1190 Exploit Public-Facing Application
  - T1133 External Remote Services
  - T1003 OS Credential Dumping
Software: STELLARPARTICLE, WELLMESS, MimiKatz
C2-mønster: Compromised SaaS, cloud-relay
Reference: https://attack.mitre.org/groups/G0016/
```

## Etisk note

- **Adversary emulation kræver skriftlig tilladelse + blue team-
  koordination.** "Live-fire" uden notice kan udløse incident-respons,
  juridisk eksponering og skade på drift.
- **Brug ikke rigtig malware** medmindre engagement-kontrakten
  eksplicit dækker det og target er fuldt isoleret.
- **CTI-data har TLP-mærkning** (TLP:RED/AMBER/GREEN/WHITE) — respektér
  delings-restriktioner.
- IoCs delt videre i rapport bør være redacted hvor relevant
  (interne IPs, ansattes mailadresser).

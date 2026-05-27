---
name: blueteam-hunting
description: Threat hunting — proaktiv jagt efter ikke-alarmerede aktører via hypoteser, YARA/Sigma, baseline-afvigelser, lateral movement-graf. Brug ved spørgsmål om "threat hunting", "YARA", "hunting hypothesis", "baseline anomaly", "beacon detection", "lateral movement" eller når et incident-spor skal forfølges proaktivt.
---

# Threat Hunting (Blue Team)

Brug denne skill når der skal jages proaktivt: ingen alert er
fyret endnu, men en hypotese siger at noget kan have undsluppet
detection. Forskellen fra `blueteam-detection`: hunting er
manuelt/iterativt, detection er automatiseret.

## Workflow (PEAK / TaHiTI-inspireret)

1. **Hypotese.** Formulér en testbar hypotese baseret på trussel-
   landskab eller CTI ("APT29-style cloud-relay-beaconing eksisterer
   i vores tenant").
2. **Datakilder.** List hvilke logs der ville indeholde signalet
   (proxy, DNS, EDR, IDS, cloud audit).
3. **Søgequery.** Skriv ad-hoc query (SPL/KQL/EQL). Start bredt,
   indsnævr via filtrering.
4. **Triangulér.** Sammenhold ≥2 datakilder før konklusion.
5. **Pivotér.** Fra ét fund → spred via host, user, IP, hash, parent
   process. Byg en lille graf.
6. **Konkludér.** Bekræft eller afkræft hypotesen. Dokumentér
   negative-finds — de er ligeså værdifulde som hits.
7. **Operationalisér.** Lav fundet om til en detection-rule (overdrag
   til `blueteam-detection`).

## Hunt-hypotese-bibliotek (eksempler)

- **Beaconing:** konstant interval-baseret HTTP/DNS-trafik fra ikke-
  user-driven processer.
- **Living-off-the-land:** signed binaries (rundll32, wmic, mshta)
  med eksterne network-connections.
- **Lateral movement:** SMB/RPC-trafik fra non-admin-workstations til
  andre workstations.
- **Cloud persistence:** nye App Registrations, OAuth-grants,
  service-principal-secrets.
- **Data exfil:** store DNS-TXT-queries, store HTTPS-POSTs til ukendte
  destinationer.

## Værktøjer

*Hunting platforms:*
- [Velociraptor](https://docs.velociraptor.app/) – Endpoint hunting + DFIR.
- [Osquery](https://osquery.io/) – SQL-baseret endpoint-introspektion.
- [Kolide](https://www.kolide.com/) / [Fleet](https://fleetdm.com/) – Osquery-management.
- [GRR Rapid Response](https://github.com/google/grr) – Incident response framework.
- [HELK](https://github.com/Cyb3rWard0g/HELK) – ELK-stack tunet til hunting.

*YARA & malware:*
- [YARA](https://yara.readthedocs.io/) – Pattern-matching for malware.
- [yarGen](https://github.com/Neo23x0/yarGen) – Automatisk YARA-rule-generering.
- [Loki](https://github.com/Neo23x0/Loki) – IoC + YARA-scanner.
- [Capa](https://github.com/mandiant/capa) – Malware capability-detection.

*CTI til hunt-input:*
- [MITRE ATT&CK Navigator](https://mitre-attack.github.io/attack-navigator/) – TTP-prioritering.
- [Threat Hunter Playbook](https://threathunterplaybook.com/) – Notebooks med hunt-hypoteser.
- [Splunk Boss of the SOC](https://github.com/splunk/botsv3) – Dataset til træning.

*Network analysis:*
- [Zeek](https://zeek.org/) – Network monitor.
- [Suricata](https://suricata.io/) – IDS/IPS + protokol-logging.
- [RITA](https://github.com/activecm/rita) – Beacon-detection + DNS-tunnel-detection.
- [Arkime](https://arkime.com/) – Full-packet-capture analyse.

## Hunt-template

```text
Hunt-ID:        H-2026-001
Hypotese:       APT29-style OAuth-token-theft i M365-tenant
ATT&CK:         T1528 Steal Application Access Token
Datakilder:     AzureAD AuditLogs, M365 UnifiedAuditLog
Query (KQL):
  AuditLogs
  | where OperationName == "Consent to application"
  | where Result == "success"
  | where ConsentContext.IsAdminConsent == false
  | extend AppName = tostring(TargetResources[0].displayName)
  | summarize count() by AppName, InitiatedBy

Pivots:         App-display-name → permission-graph
Findings:       <log>
Outcome:        Bekræftet/Afkræftet
Detection?:     <ja/nej + ID hvis lavet>
```

## Etisk note

- **Hunting touches user-data.** Sørg for at access-loggen på dine
  queries er gennemsigtig over for compliance/DPO.
- **Bias-awareness:** undgå at hypotesen er en confirmation-search
  mod en enkelt bruger uden grundlag.
- **Operationsdisciplin:** del hunt-fund med IR-teamet før eskalering
  til ledelse eller eksterne.

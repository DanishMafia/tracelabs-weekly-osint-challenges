---
name: blueteam-detection
description: Detection engineering — SIEM/EDR-queries (Splunk SPL, KQL/Sentinel, Elastic), Sigma-regler, alert-tuning, false-positive-reduktion. Brug ved spørgsmål om "detection rule", "Sigma", "SPL", "KQL", "EDR query", "alert tuning", "false positive" eller når der skal skrives/auditeres en detection.
---

# Detection Engineering (Blue Team)

Brug denne skill når en detection skal skrives, oversættes mellem
platforme, eller tunes for færre falske positiver. Defensiv pendant
til `redteam-ttp` — samme TTPs, men nu set fra SIEM-/EDR-siden.

## Workflow

1. **Start fra en TTP, ikke en IoC.** IoCs ældes hurtigt; TTPs holder.
   Forankrer regelen i MITRE ATT&CK (T-nummer).
2. **Hypotese.** Hvilken telemetri ville denne TTP producere?
   (Sysmon-EID, EDR-process-event, network-flow, auth-log.)
3. **Skriv Sigma først.** Platform-agnostisk regel der kan konverteres
   til SPL/KQL/Elastic via `sigmac`/`pySigma`.
4. **Validér med adversary emulation.** Atomic Red Team eller CALDERA
   trigger telemetri → bekræft at regelen fyrer.
5. **Tune for FP.** Identificér baseline-noise (admin-konti, scheduled
   tasks, scanning-værktøjer). Tilføj exclusions, kontekst-betingelser.
6. **Risk-score & severity.** Sæt severity baseret på TTP-kritikalitet
   og data-følsomhed.
7. **Document & version.** Tilknyt ATT&CK-mapping, beskrivelse,
   testdata, change-log.

## Værktøjer

*Detection rule formats:*
- [Sigma](https://github.com/SigmaHQ/sigma) – Platform-agnostisk detection-rule-format.
- [SigmaHQ rule repo](https://github.com/SigmaHQ/sigma/tree/master/rules) – 3000+ community-regler.
- [pySigma](https://github.com/SigmaHQ/pySigma) – Python-konvertering til SIEM-formater.
- [Uncoder.io](https://uncoder.io/) – Online Sigma-konvertering mellem platforme.

*Platform-specifikke query-sprog:*
- [Splunk SPL](https://docs.splunk.com/Documentation/Splunk/latest/SearchReference/) – Splunk Search Processing Language.
- [KQL (Kusto)](https://learn.microsoft.com/en-us/azure/data-explorer/kusto/query/) – Microsoft Sentinel / Defender / Log Analytics.
- [EQL](https://eql.readthedocs.io/) – Elastic Event Query Language.
- [LogQL](https://grafana.com/docs/loki/latest/query/) – Grafana Loki query.
- [Carbon Black/CrowdStrike CQL] – EDR-specifikke query-sprog.

*Detection development & testing:*
- [Atomic Red Team](https://github.com/redcanaryco/atomic-red-team) – Trigger-tests mappet til ATT&CK.
- [CALDERA](https://github.com/mitre/caldera) – Automated adversary emulation.
- [DetectionLab](https://github.com/clong/DetectionLab) – Lab-miljø til detection-udvikling.
- [HELK](https://github.com/Cyb3rWard0g/HELK) – Hunting ELK-stack.

*Rule libraries:*
- [Elastic Detection Rules](https://github.com/elastic/detection-rules)
- [Splunk Security Content](https://github.com/splunk/security_content)
- [Sentinel Community Rules](https://github.com/Azure/Azure-Sentinel)
- [Panther Analysis](https://github.com/panther-labs/panther-analysis)

## Skabelon: Sigma-regel

```yaml
title: Suspicious LOLBin Execution via WMIC
id: <uuid>
status: experimental
description: Detects wmic.exe spawning powershell.exe (T1218)
references:
  - https://attack.mitre.org/techniques/T1218/
author: '@your_handle'
date: 2026/05/27
tags:
  - attack.defense_evasion
  - attack.t1218
logsource:
  category: process_creation
  product: windows
detection:
  selection:
    ParentImage|endswith: '\wmic.exe'
    Image|endswith: '\powershell.exe'
  condition: selection
falsepositives:
  - Legitimate admin scripts using WMIC + PowerShell
level: high
```

## Anti-patterns

- **Alert på enkelt IoC** uden kontekst → falske positiver eller
  trivielle bypasses.
- **Regel uden ATT&CK-mapping** → svært at prioritere coverage.
- **Manglende `falsepositives`-felt** → drukner SOC i støj.

## Etisk note

- **Detections skal testes mod aftalt scope.** Adversary emulation
  kan udløse incident-respons hvis ikke koordineret.
- **Del Sigma-regler tilbage til community** når relevant — defensiv
  viden bør være offentlig.
- Pas på at detection-data ikke lækker PII til usikrede destinationer
  (Slack-notifications, eksterne SIEM-vendors).

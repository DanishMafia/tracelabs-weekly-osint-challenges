---
name: blueteam-logs
description: Log-analyse og forensic timeline-rekonstruktion — Sysmon, Windows Event Logs, Linux auditd, web-/proxy-/DNS-logs, cloud audit (AzureAD, AWS CloudTrail, GCP). Brug ved spørgsmål om "log analysis", "Sysmon", "auditd", "Event ID", "CloudTrail", "AzureAD signins", "timeline", "log forensics" eller når rå logs skal læses.
---

# Log Analysis (Blue Team)

Brug denne skill når rå telemetri skal læses, korreleres og
forvandles til en timeline. Bygger ovenpå `blueteam-hunting` —
forskellen er at hunting er hypotese-drevet, log-analyse er
typisk evidens-drevet (efter et alert/incident).

## Workflow

1. **Definér tidsvindue.** Start 1–7 dage før første kendte
   indicator. Udvid hvis dwell-time-bevis stiger.
2. **Sammenkør tidszoner.** Konverter alt til UTC før korrelation —
   blandede tidszoner skjuler sammenfald.
3. **Korrelér på pivot-felter.** Host, user, process, hash, IP,
   domain. Én pivot ad gangen.
4. **Triangulér ≥2 kilder.** Process-event + network-event +
   filesystem-event er stærkere end ét alene.
5. **Timeline.** Eksportér tid+kilde+felt+værdi til CSV →
   timesketch/Plaso/Excel.
6. **Identificér gaps.** Hvor mangler der logging? Det er
   blue team-action item.

## Vigtigste log-kilder

### Windows

| Event ID | Log | Hvorfor |
|---|---|---|
| 1 | Sysmon | Process create (cmdline + parent) — krydre alt |
| 3 | Sysmon | Network connect |
| 7 | Sysmon | Image load (DLL injection) |
| 11 | Sysmon | File create |
| 13 | Sysmon | Registry value set |
| 4624 | Security | Logon success (LogonType=3 lateral, 10 RDP) |
| 4625 | Security | Logon failure (brute force-mønster) |
| 4688 | Security | Process create (lighter end Sysmon-1) |
| 4720 | Security | User account created |
| 4768/9 | Security | Kerberos TGT/TGS (golden ticket-mønster) |
| 7045 | System | Service installed (persistence) |
| 4104 | PowerShell | Script block logging |

### Linux

- `/var/log/auth.log` – sshd, sudo, su
- `/var/log/audit/audit.log` – auditd-events (kræver `auditctl`-regler)
- `journalctl` – systemd-services
- `~/.bash_history`, `~/.zsh_history` – kommando-historik (kan
  manipuleres)
- `/var/log/wtmp`, `/var/log/btmp`, `/var/log/lastlog` – login-historik
- `/proc/<pid>/` – live process-state under triage

### Cloud

- **AWS CloudTrail** – API-calls. Vigtigste events: `CreateUser`,
  `AttachUserPolicy`, `ConsoleLogin`, `AssumeRole`, `GetSecretValue`.
- **Azure AD Sign-in Logs** – interaktive + non-interactive.
  `RiskLevel`, `ConditionalAccessStatus`, `DeviceDetail`.
- **Azure AD Audit Logs** – directory-ændringer (rolle-tildelinger,
  app-consents).
- **M365 Unified Audit Log** – Exchange, SharePoint, Teams.
- **GCP Cloud Audit** – Admin Activity + Data Access.

### Web/network

- **Proxy logs** – squid, Zscaler, Netskope: domæner besøgt + bytes.
- **DNS logs** – Bind/PowerDNS, Sysmon-EID-22, Zeek `dns.log`.
- **Firewall flows** – connection-records (deny + allow).
- **Web server access logs** – referrer, user-agent, response-codes.

## Værktøjer

*Parsing & timeline:*
- [Plaso/log2timeline](https://plaso.readthedocs.io/) – Genererer "super timeline" på tværs af artefakter.
- [Timesketch](https://timesketch.org/) – Collaborative timeline-analyse.
- [Chainsaw](https://github.com/WithSecureLabs/chainsaw) – Hurtig Sigma-mod-EVTX.
- [EvtxECmd](https://github.com/EricZimmerman/evtx) – EVTX-parser.
- [hayabusa](https://github.com/Yamato-Security/hayabusa) – Windows Event Log threat-hunting.

*Search & SIEM-CLI:*
- `splunk` CLI / Splunk REST API.
- `az monitor log-analytics` – KQL fra CLI.
- `aws logs` – CloudWatch Logs.
- [zq](https://github.com/brimdata/zui) – Zeek-log-query.
- `jq` – JSON-parsing af cloud-logs.

*Specialized:*
- [Zeek](https://zeek.org/) – Network protocol-logging.
- [RITA](https://github.com/activecm/rita) – Beacon/DNS-tunnel-detection over Zeek-logs.
- [DeepBlueCLI](https://github.com/sans-blue-team/DeepBlueCLI) – Heuristisk Windows-log-analyse.

## Hurtige one-liners

```bash
# Sysmon EID 1: alle PowerShell-børn af Office
chainsaw search --tau rules/sigma -t evtx_directory ./logs

# AWS CloudTrail: hvem brugte hvilken AssumeRole?
aws logs filter-log-events --log-group-name /aws/cloudtrail \
  --filter-pattern '{ $.eventName = "AssumeRole" }' \
  | jq '.events[].message | fromjson | {time:.eventTime, user:.userIdentity.arn, role:.requestParameters.roleArn}'

# Linux: failed logins seneste 24t
journalctl --since "24 hours ago" _SYSTEMD_UNIT=ssh.service | grep "Failed password"

# Splunk SPL: rare process-trees
index=sysmon EventID=1 | rare ParentImage Image limit=20
```

## Anti-patterns

- **Læser logs i lokal tidszone** uden konvertering → fejlkorrelation.
- **Søger på en enkelt log-kilde** uden triangulering → narrative-bias.
- **Stoler på `.bash_history`** uden at tjekke modificeret tidspunkt.
- **Begrænset retention** — hvis logs kun opbevares 7 dage, kan du
  ikke undersøge dwell-time. Det er en blue team-action item.

## Etisk note

- **Logs indeholder PII.** Følg need-to-know-princip ved deling.
- **Logging-gaps er ikke en undskyldning** — dokumentér og forbedr
  retention/coverage som lessons-learned-output.
- **Tamper-evidence.** Vurder log-integrity (signed logs, WORM-
  storage) før evidens accepteres juridisk.

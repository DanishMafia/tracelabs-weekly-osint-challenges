---
name: blueteam-ir
description: Incident response workflow — triage, containment, eradication, recovery, lessons-learned. NIST SP 800-61 + SANS PICERL. Brug ved spørgsmål om "incident response", "IR playbook", "containment", "ransomware response", "breach", "PICERL", "SOC handoff" eller når en aktiv hændelse skal struktureres.
---

# Incident Response (Blue Team)

Brug denne skill når en hændelse er bekræftet eller stærkt mistænkt.
Følger PICERL / NIST SP 800-61.

## Workflow — PICERL

1. **Preparation.** (Før hændelse.) IR-plan, runbooks, kontakt-tree,
   forensics-toolkit klar, juridisk-/PR-eskalering aftalt.
2. **Identification.** Bekræft scope — er det reel kompromittering
   eller false positive? Triangulér via EDR + netværks-logs + auth-
   logs. Sæt severity og IR-leder.
3. **Containment.**
   - *Short-term:* isolér ramte hosts (EDR-isolate), block C2-IPs,
     disable kompromitterede konti.
   - *Long-term:* netværks-segmentering, opdaterede AC-regler,
     mid-incident credential-rotation.
4. **Eradication.** Fjern persistence (scheduled tasks, services,
   registry-keys), genscan med opdaterede signatures, patch root-
   cause-CVE.
5. **Recovery.** Genopret fra clean backups, valider integrity
   (filhash, app-funktionalitet), forhøjet monitoring i 30+ dage.
6. **Lessons learned.** Post-mortem inden 2 uger — root cause, MTTD,
   MTTR, kontrol-gaps, action items med ejer + deadline.

## Triage-rækkefølge

```text
1. STOP exfil/eskalation:  isolér host, block C2
2. PRESERVE:               disk-image, RAM-dump, log-snapshot
3. ASSESS scope:           lateral spread, indirekte ramte
4. NOTIFY:                 ledelse, juridisk, kunder, DPA, CSIRT
5. INVESTIGATE:            timeline-rekonstruktion
6. REMEDIATE:              patch, rotér creds, re-image
7. REPORT:                 post-mortem + regulatorisk anmeldelse
```

## Ransomware-specifikt

- **Betal ikke** uden juridisk konsultation (sanctions, OFAC-tjek).
- Bevar én krypteret prøve + ransomnote til reverse engineering.
- Tjek [No More Ransom](https://www.nomoreransom.org/) for decryptor.
- Vurder **double-extortion** — er der data-leak truet?
- GDPR-anmeldelse til DPA inden 72 timer hvis personoplysninger
  ramt (EU).

## Værktøjer

*IR-orkestrering / case management:*
- [TheHive](https://thehive-project.org/) – Open source SOC/IR-platform.
- [Velociraptor](https://docs.velociraptor.app/) – Cross-platform endpoint IR + hunting.
- [GRR Rapid Response](https://github.com/google/grr) – Remote forensics.
- [DFIR-IRIS](https://dfir-iris.org/) – Collaborative IR-platform.

*Live response & triage:*
- [KAPE](https://www.kroll.com/en/services/cyber-risk/incident-response-litigation-support/kroll-artifact-parser-extractor-kape) – Targeted triage-collection.
- [CyLR](https://github.com/orlikoski/CyLR) – Live response-collector.
- [Sysinternals Suite](https://learn.microsoft.com/en-us/sysinternals/) – Windows-introspektion.

*Forensics & memory:*
- [Volatility 3](https://volatility3.readthedocs.io/) – Memory forensics.
- [Autopsy](https://www.autopsy.com/) – GUI disk-forensics.
- [Eric Zimmerman tools](https://ericzimmerman.github.io/) – Windows artifact-parsers.
- [Plaso/log2timeline](https://plaso.readthedocs.io/) – Timeline-genererer.

*Containment & cleanup:*
- EDR-platformens isolate-funktion (CrowdStrike, SentinelOne, Defender).
- AD-disable-user + force password reset.
- Cloud: IAM-access-revoke, MFA-reset.

## Runbook-template

```text
Playbook:     Suspected Ransomware
Severity:     High
IR Lead:      <name>
Comms:        #ir-channel-2026-001

PHASE 1 — Identification (15 min)
  [ ] Bekræft via EDR + filesystem-monitor
  [ ] Identificér patient zero + lateral spread

PHASE 2 — Containment (30 min)
  [ ] EDR-isolate ramte hosts
  [ ] Block C2 på perimeter
  [ ] Disable kompromitterede konti

PHASE 3 — Eradication (variabel)
  [ ] Identificér variant (note + hash → ID-Ransomware)
  [ ] Find initial vector (phish, RDP, exploit)
  [ ] Fjern persistence

PHASE 4 — Recovery
  [ ] Re-image fra clean baseline
  [ ] Genskab fra backup (verificeret offline-kopi)
  [ ] Forhøjet logging 30 dage

PHASE 5 — Lessons (≤14 dage)
  [ ] Post-mortem
  [ ] Action items med deadline
  [ ] Opdater playbook
```

## Etisk note

- **Bevisførelse.** Følg chain-of-custody for evt. juridisk
  efterforskning — dokumentér hvem rørte hvad, hvornår.
- **Kommunikation.** Brug out-of-band comms (mobil, Signal) hvis
  email/Slack potentielt kompromitteret.
- **GDPR/regulatorisk.** Anmeld breaches inden lovkrav (typisk
  72 timer i EU).
- **Personlige data.** Begræns adgang til IR-evidence til need-to-know.

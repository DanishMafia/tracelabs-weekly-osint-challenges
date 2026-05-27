---
name: redteam-surface
description: Attack surface mapping for autoriserede red-team-engagements — subdomæner, eksponerede services, tech-stack-fingerprinting, cloud-assets (S3/GCS/Azure). Brug ved spørgsmål om "attack surface", "asset discovery", "subdomain enum", "cloud bucket", "tech stack", "fingerprint" eller pre-engagement-recon mod et godkendt mål.
---

# Attack Surface Mapping (Red Team)

Brug denne skill når et **autoriseret** red-team-engagement starter og
målets eksterne attack surface skal kortlægges. Fokus er passiv +
let-aktiv rekognoscering — bygger ovenpå `osint-infrastructure` med
red-team-vinklen "hvad kan udnyttes".

## Workflow

1. **Scope-bekræftelse.** Bekræft skriftligt scope (domæner, IP-ranges,
   cloud-tenants). Alt udenfor → stop.
2. **Passive subdomain enum.** Certificate Transparency (crt.sh,
   Censys), passive DNS (SecurityTrails, VirusTotal), søgemaskine-dorks.
3. **Active subdomain enum.** Brute-force kun mod in-scope domæner
   (Amass, Subfinder, ffuf med wordlist).
4. **Live host probing.** `httpx`/`httprobe` for at filtrere live
   services. Notér status, titel, tech-stack.
5. **Tech-stack-fingerprinting.** Wappalyzer, WhatWeb, BuiltWith.
   Versions-info → koble til CVE-databaser.
6. **Port/service-enum.** Nmap, Naabu mod in-scope IPs. Banner-grab
   uden exploit-payload.
7. **Cloud-asset-discovery.** S3 (cloud_enum, S3Scanner), GCS, Azure
   Blob. Tjek både listed buckets og brute-force navne baseret på
   org-navnet.
8. **Konsolidering.** Eksportér til Maltego/Obsidian-graf — markér
   high-value assets (admin-paneler, dev-miljøer, gamle apps).

## Værktøjer

*Passive enumeration:*
- [crt.sh](https://crt.sh) – Certificate Transparency-søgning.
- [Amass](https://github.com/owasp-amass/amass) – Subdomain enum + asset-mapping.
- [Subfinder](https://github.com/projectdiscovery/subfinder) – Passive subdomain discovery.
- [Sublist3r](https://github.com/aboul3la/Sublist3r) – Subdomain enum via søgemaskiner og CT.
- [SecurityTrails](https://securitytrails.com/) – Passive DNS-historik.

*Live probing & fingerprinting:*
- [httpx](https://github.com/projectdiscovery/httpx) – Hurtig HTTP-prober.
- [Naabu](https://github.com/projectdiscovery/naabu) – Hurtig port-scanner.
- [Nmap](https://nmap.org/) – Service/version-detection.
- [WhatWeb](https://github.com/urbanadventurer/WhatWeb) – Tech-stack-fingerprinting.
- [Wappalyzer](https://www.wappalyzer.com/) – Tech-stack via browser/CLI.

*Cloud asset discovery:*
- [cloud_enum](https://github.com/initstring/cloud_enum) – AWS/GCP/Azure-asset-enumerering.
- [S3Scanner](https://github.com/sa7mon/S3Scanner) – S3-bucket-enumerering.
- [GCPBucketBrute](https://github.com/RhinoSecurityLabs/GCPBucketBrute) – GCS-bucket-brute-force.

## Pivots og signaler

- **Dev/staging-subdomæner** (`dev.`, `staging.`, `test.`) lækker ofte
  flere services end produktion.
- **Forskellige tech-stacks i samme org** → akkvisitioner, M&A, legacy.
- **Cloud-bucket-navne** brute-forces ud fra org-aliasser, projekt-koder,
  produktnavne.
- **CDN-bypass** via origin-IP fundet i CT eller historisk DNS.

## Etisk note

- **Kun mod skriftligt autoriseret scope.** Brute-force og aktiv
  scanning af out-of-scope assets er ofte ulovligt og altid
  unprofessionelt.
- Hold rate-limits lave nok til ikke at udløse alarmer eller DoS.
- Dokumentér alt input/output med tidsstempler — bevisførelse ved
  evt. tvist.
- Cloud-buckets: list-only er passivt, men **hent ikke** data fra
  exposed buckets uden eksplicit godkendelse.

---
name: osint-infrastructure
description: Domæne-, IP- og infrastruktur-OSINT — Shodan, Censys, WHOIS, DNS, certifikater, banner-grabbing. Brug ved spørgsmål om "Shodan", "Censys", "WHOIS", "DNS lookup", "IP recon", "exposed device", eller når et domæne/IP er artefakt.
---

# Domain / IP / Infrastructure (OSINT)

Brug denne skill når sporet er et domæne, en IP, et certifikat eller en
internet-eksponeret tjeneste.

## Workflow

1. **WHOIS + DNS først.** Registrar, oprettelsesdato, MX, NS, TXT
   (SPF/DMARC).
2. **Certifikat-historik.** crt.sh / Censys viser tidligere certifikater
   → afslører subdomæner.
3. **Shodan/Censys** for åbne porte, bannere, sårbare versioner.
4. **Passive DNS** for at se hvilke navne der historisk har peget på en
   IP.
5. **Pivotér via hosting** — samme IP-block kan rumme relaterede
   tjenester.

## Værktøjer (fra Trace Labs / awesome-osint, MPL-2.0)

*Search engines and tools for investigating internet infrastructure.*

- [Shodan](https://www.shodan.io/) – Search engine for internet-connected devices.
- [Censys](https://censys.com/) – Internet-wide scanning and intelligence platform.

## Yderligere værktøjer (fra Trace Labs OSINT VM, GPL-3.0)

- **Sublist3r** – Subdomæne-enumerering via passive kilder (søgemaskiner, certifikater).
- **OSRFramework – Domainfy** – Tjekker domænenavns-tilgængelighed på tværs af TLDs.
- **Shodan CLI** – Command-line interface til Shodan.
- **Photon** – Hurtig web-crawler til at indsamle URLs, e-mails, parametre og keys fra en side.

## Companion-recipe

`.claude/recipes/shodan-recon.sh` wrapper Shodan API:

```bash
export SHODAN_API_KEY=...
./.claude/recipes/shodan-recon.sh info                              # credits + plan
./.claude/recipes/shodan-recon.sh host 8.8.8.8                      # services, vulns, certs
./.claude/recipes/shodan-recon.sh count 'product:nginx country:DK'  # gratis
./.claude/recipes/shodan-recon.sh facet 'org:"Example Inc"' port    # top porte
./.claude/recipes/shodan-recon.sh dns example.com,sub.example.com   # → IPs
./.claude/recipes/shodan-recon.sh reverse 1.2.3.4                   # → hostnames
```

`count` og `facet` koster ingen query-credits — brug dem til volumen-
spørgsmål før du laver `host`/`search`-opslag der trækker credits.

## Etisk note

- **Kun passive opslag.** Ingen aktiv scanning af mål uden eksplicit
  tilladelse — det kan være ulovligt.
- Shodan/Censys data er allerede indsamlet — at slå op er passivt; at
  forbinde til en host er aktivt.

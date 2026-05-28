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

## Companion-recipes

**Shodan** (`.claude/recipes/shodan-recon.sh`):

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

**Censys** (`.claude/recipes/censys-recon.sh`) — stærk på cert-historik
og host-attribuering. To auth-modes med forskellige capabilities:

```bash
# Platform API v3 (nyere, Bearer PAT)
export CENSYS_USER=you@example.com
export CENSYS_TOKEN=censys_...
export CENSYS_ENDPOINT=https://api.platform.censys.io/v3
./.claude/recipes/censys-recon.sh host 8.8.8.8
./.claude/recipes/censys-recon.sh hosts 8.8.8.8,1.1.1.1            # batch
./.claude/recipes/censys-recon.sh timeline 1.1.1.1 --from 2026-04-01
./.claude/recipes/censys-recon.sh web dns.google:443                # webproperty
./.claude/recipes/censys-recon.sh cert <sha256>

# Search v2 (klassisk, Basic Auth — search + aggregate)
export CENSYS_USER=<API_ID>
export CENSYS_TOKEN=<API_SECRET>
./.claude/recipes/censys-recon.sh search 'services.service_name: HTTP and location.country_code: DK'
./.claude/recipes/censys-recon.sh aggregate 'services.service_name: SSH' services.port
./.claude/recipes/censys-recon.sh cert-search 'names: example.com'
```

**Vigtigt:** Platform v3 PAT understøtter KUN direct asset-lookup
(host, cert, webproperty, timeline). `search`/`aggregate` kræver
Search v2-credentials (API ID + secret). Recipe fejler klart hvis du
forsøger en subkommando der ikke matcher mode.

**Punktum .dk lookup** (`.claude/recipes/whois-dk-hostmaster.sh`)
— DK Hostmaster er rebrandet til **Punktum dk** (`punktum.dk`).
Recipe'n tjekker .dk-TLD-validering, prober Punktum-endpointet,
forsøger port-43 WHOIS (`whois.punktum.dk`) og printer den korrekte
manuelle lookup-URL:

```bash
./.claude/recipes/whois-dk-hostmaster.sh domain nationalbanken.dk
./.claude/recipes/whois-dk-hostmaster.sh bulk nationalbanken.dk,nordea.dk
```

**Begrænsning:** Punktum's webform er CSRF-/JS-renderet og kan IKKE
scrapes direkte. Recipe'n leverer derfor en best-effort port-43-prøve
+ canonical URL. Til automation: kommerciel passive-DNS-feed
(SecurityTrails, DNSDB, DomainTools) eller headless browser (Playwright).

**Brug Shodan + Censys parallelt**: Shodan har bredere banner-coverage
og vuln-tags; Censys har dybere cert-historik (SAN-grafer pivoterer
til glemte subdomæner) og mere strukturerede service-data.
Krydsreferer altid for high-value findings.

## Etisk note

- **Kun passive opslag.** Ingen aktiv scanning af mål uden eksplicit
  tilladelse — det kan være ulovligt.
- Shodan/Censys data er allerede indsamlet — at slå op er passivt; at
  forbinde til en host er aktivt.

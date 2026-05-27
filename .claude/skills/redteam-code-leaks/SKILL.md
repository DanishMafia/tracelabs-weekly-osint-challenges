---
name: redteam-code-leaks
description: Find offentlige kode- og secret-læk fra autoriserede mål — GitHub-dorks, gitleaks-mod-historik, exposed .git/.env, S3-bucket-secrets, paste-sites. Brug ved spørgsmål om "github dork", "gitleaks", "trufflehog", "leaked secret", "exposed config", "paste site", "S3 leak", "GitHub recon".
---

# Code & Secret Leak Hunting (Red Team)

Brug denne skill når et **autoriseret** red-team-engagement skal lede
efter utilsigtet eksponerede secrets, credentials, infrastruktur-koder
og interne dokumenter. Fokus er passive opslag i offentlige indekser
— ikke ny scraping bag login.

## Workflow

1. **Mål-aliasser.** Org-navn, brand-navne, akkvisitioner, interne
   projekt-koder. Disse er dine søge-strenge.
2. **GitHub-dorks.** Søg på org-domæner, AWS-key-mønstre, hardcoded
   strenge (`password=`, `BEGIN PRIVATE KEY`, `api_key`). Brug også
   GitHub-org-søgning hvis org har offentlig konto.
3. **Git-historik-scan.** Klone offentlige repos i org → `gitleaks`
   eller `trufflehog` mod hele historikken (secrets slettet i HEAD
   findes ofte stadig i ældre commits).
4. **Exposed dev-artefakter.** `/.git/config`, `/.env`, `/web.config`,
   `/phpinfo.php`, `/server-status` på live hosts (kun in-scope).
5. **Paste-sites.** Pastebin, JustPaste, ghostbin, doxbin — søg på
   org-domæner og e-mail-mønstre via Google og PasteSearch.
6. **Cloud-bucket-secrets.** Listede S3/GCS-buckets: tjek for
   `.env`, `backup.sql`, `.tar.gz` (kun hvis kontrakt tillader
   download).
7. **Container-registries.** Docker Hub, GitHub Container Registry —
   public images kan indeholde indlejrede secrets.
8. **Verificér.** Test ikke fundne credentials mod produktion uden
   eksplicit godkendelse — afrapportér først.

## Værktøjer

*Source code search:*
- [GitHub Code Search](https://github.com/search) – Brug `org:`, `filename:`, `path:`, `extension:` operatorer.
- [grep.app](https://grep.app/) – Hurtig kode-søgning på tværs af GitHub.
- [Sourcegraph](https://sourcegraph.com/search) – Avanceret kode-søgning med regex.
- [PublicWWW](https://publicwww.com/) – Søg i HTML/JS/CSS-source af offentlige sider.

*Secret scanning:*
- [gitleaks](https://github.com/gitleaks/gitleaks) – Secret-scan på git-historik.
- [TruffleHog](https://github.com/trufflesecurity/trufflehog) – Secret-scan med live-verifikation.
- [GitDorker](https://github.com/obheda12/GitDorker) – Automatiseret GitHub-dork-runner.
- [shhgit](https://github.com/eth0izzle/shhgit) – Realtids-monitor af GitHub-events for secrets.

*Paste-site search:*
- [PasteHunter](https://github.com/kevthehermit/PasteHunter) – Monitorerer paste-sites for leaks.
- [DumpsterDiver](https://github.com/securing/DumpsterDiver) – Analyserer dumps for secrets.

*Container & artifact registries:*
- [docker-explorer](https://github.com/google/docker-explorer) – Analyse af Docker-image-lag.
- `dive` – Inspicér Docker-image-lag for embedded secrets.

## GitHub-dork-bibliotek (eksempler)

```text
org:<org>             "password"
org:<org>             "BEGIN RSA PRIVATE KEY"
"<org-domain>"        "smtp.gmail.com"
"<org-domain>"        filename:.env
"<org-domain>"        filename:wp-config.php
extension:pem         "<org-domain>"
"AKIA"                "<org-name>"     # AWS access keys
```

## Pivots

- **En fundet secret → kortlæg blast radius** (samme key i flere
  repos? Stadig aktiv?) før rapport.
- **Slettede repos** ligger ofte stadig i GitHub-events API i op til
  90 dage — pivotér via commit-hash.
- **Forks med fjernede secrets** beholder ofte secret i deres historik.

## Etisk note

- **Kun mod skriftligt autoriseret scope.** At lede er passivt; at
  *bruge* en fundet credential er aktivt og kræver eksplicit
  godkendelse i kontrakten.
- **Rapportér ansvarligt.** Hvis du finder et leak udenfor scope der
  rammer tredjepart, følg responsible-disclosure-procedure.
- **Slet downloadede secrets** efter engagement — opbevar kun
  redacted-hashes som evidens.
- **Ingen scraping bag login.** GitHub-private repos, paywalled
  paste-sites osv. er off-limits.

---
name: redteam-phishing-recon
description: Pre-engagement recon til autoriserede phishing/social-engineering-tests — e-mail-format-discovery, employee-enumerering (LinkedIn/Hunter), breach-data via HIBP, kontekstuel pretexting-research. Brug ved spørgsmål om "phishing recon", "email format", "employee enum", "HIBP", "breach", "Hunter.io", "pretext", "OSINT for social engineering".
---

# Phishing & Social Engineering Recon (Red Team)

Brug denne skill når et **autoriseret** phishing-/social-engineering-engagement
skal forberedes. Fokus er at samle den offentligt tilgængelige
information om målet som muliggør målrettet, troværdig pretexting.

## Workflow

1. **Engagement-scope.** Bekræft skriftlig tilladelse, in-scope
   targets, hvilke pretexts der er aftalt (HR, IT, leverandør),
   eskaleringskanal ved succesfuld kompromittering.
2. **E-mail-format-discovery.** Hunter.io, Skymem,
   `theHarvester` mod org-domænet → udled mønster (`{first}.{last}@`,
   `{f}{last}@`).
3. **Employee enum.** LinkedIn (manuel + ScrapedIn/CrossLinked), org-chart
   fra offentlige kilder (årsrapporter, om-os-sider, presse).
4. **Breach data.** Have I Been Pwned (kontonavne, ikke passwords),
   IntelX/Dehashed (kun hvis kontrakten tillader det og data er
   lovligt erhvervet).
5. **Pretexting-research.** Org-newsletter, blog-posts, Glassdoor
   (vendor-stack, intern lingo), seneste M&A-nyheder, fælles-
   leverandører (Salesforce, AWS, Slack).
6. **Infra-bekræftelse.** SPF/DKIM/DMARC på org-domænet → kortlæg om
   spoofing er muligt eller om vi skal bruge lookalike-domæner.
7. **Lookalike-domain-registrering.** dnstwist genererer kandidater;
   vælg ét der ligner og registrér via godkendt registrar.
8. **Template-design.** Brug indsamlet kontekst (HR-portal-skin,
   leverandør-mail-stil) til en troværdig phish.

## Værktøjer

*Email/employee discovery:*
- [theHarvester](https://github.com/laramies/theHarvester) – E-mail, subdomain, employee-enum via offentlige kilder.
- [Hunter.io](https://hunter.io/) – E-mail-format-discovery på domæner.
- [Skymem](http://www.skymem.info/) – Gratis e-mail-søgning pr. domæne.
- [CrossLinked](https://github.com/m8sec/CrossLinked) – LinkedIn-employee-enum uden auth.
- [ScrapedIn](https://github.com/m8sec/scrapedin) – LinkedIn-data-extraction (kræver konto).

*Breach intelligence:*
- [Have I Been Pwned](https://haveibeenpwned.com/) – Breach-domain-search (kontonavne).
- [DeHashed](https://www.dehashed.com/) – Breach-database (betalt, scope-tjek først).
- [IntelX](https://intelx.io/) – Leaked dokumenter og kredentialer.

*Infrastructure & lookalikes:*
- [dnstwist](https://github.com/elceef/dnstwist) – Lookalike-domæne-generator.
- [URLCrazy](https://github.com/urbanadventurer/urlcrazy) – Typo-squat-domain-generator.
- [MXToolbox](https://mxtoolbox.com/) – SPF/DKIM/DMARC-tjek.

*Phishing-frameworks (selve leveringen):*
- [GoPhish](https://getgophish.com/) – Open source phishing-framework.
- [Evilginx2](https://github.com/kgretzky/evilginx2) – Reverse-proxy phishing (MFA-bypass) — kun ved eksplicit godkendt scope.

## Pretexting-input

Felter du typisk vil have klar før kampagnen sendes:

- E-mail-mønster (verificeret mod 3+ kendte konti)
- Navne + titler på 10–20 in-scope ansatte
- Org-chart-skitse (hvem rapporterer til hvem)
- Top 3 leverandører/SaaS (mail-templates kan kopieres)
- Sidste nyheds-item (M&A, ny CEO, ny intranet-rollout)
- SPF/DMARC-status → spoof eller lookalike

## Companion-recipes

**Google Safe Browsing screening** (`.claude/recipes/safebrowsing-check.sh`)
— klassificér én eller flere URLs mod Googles offentlige threat-database
(MALWARE, SOCIAL_ENGINEERING, UNWANTED_SOFTWARE, POTENTIALLY_HARMFUL).
Bruges typisk til at:

- Krydstjekke lookalike-domæner FØR de bruges → hvis du er flagget
  inden engagement starter, vælg et nyt domæne.
- Verificere mistænkte URLs fra trusler/breach-feeds (defensiv brug).
- Baseline-screene en domæne-portfølje før HIBP/dehashed-pivots.

```bash
export SAFEBROWSING_API_KEY=<key fra Google Cloud Console>
./.claude/recipes/safebrowsing-check.sh url https://nationalbanken.xyz
./.claude/recipes/safebrowsing-check.sh batch https://a.com,https://b.com
cat suspect-urls.txt | ./.claude/recipes/safebrowsing-check.sh stdin
```

Gratis tier: 10k lookups/dag. Batch op til 500 URLs per call.

## Etisk note

- **Kun mod skriftligt autoriseret scope og pretext.** Phishing uden
  tilladelse er en straffelovsovertrædelse i de fleste lande.
- **Ingen reelle credentials** opbevares længere end engagement-perioden
  — slet efter rapportering.
- **PII** om enkelte ansatte holdes ude af PoC-screenshots i
  slutrapporten.
- Have I Been Pwned-data: brug kun til at konstatere at en konto var
  i en breach; **slå ikke** passwords op via gråzone-databaser uden
  kontraktlig dækning.
- Lookalike-domæner: nedlæg dem efter engagement, så de ikke
  genbruges af reelle angribere.

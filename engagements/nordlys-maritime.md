# Engagement-spec: Nordlys Maritime Logistics A/S

> **Eksempel-engagement.** Fiktiv kunde. Dette dokument viser hvordan
> hele toolboxen (OSINT + red team + blue team) kan kombineres i ét
> sammenhængende kommercielt forløb. Brug som skabelon ved scoping af
> rigtige engagements — kopiér strukturen, udskift kunde og scope.

---

## 1. Kundebrief

**Virksomhed:** Nordlys Maritime Logistics A/S (fiktiv)
**Branche:** Internationalt shipping og containerlogistik
**Hovedkontor:** København
**Størrelse:** ~350 medarbejdere, hovedkontor + datterselskaber i Hamburg, Klaipėda og Gdynia
**Tech-stack:** Microsoft 365, Azure AD, on-prem AD (Server 2019), SAP S/4HANA, custom port-management-portal, on-vessel IoT (Inmarsat), AWS-workloads (cargo-tracking-API)
**Kontaktperson:** CISO + bestyrelsens revisionsudvalg

### Anledning

Bestyrelsen har bedt om en uafhængig vurdering efter tre signaler de
seneste 90 dage:

1. **CEO-fraud-forsøg.** En tysk kunde modtog falsk faktura med Nordlys'
   layout og e-mail signaturlinjer — fra et lookalike-domæne.
2. **Impersonation af CEO** på X (Twitter) med en konto der reposter
   reelle Nordlys-nyheder og DM'er kunder med "personlige tilbud".
3. **Mistanke om data-exfil.** En operations-medarbejder fratrådte på
   dårlige vilkår. IT-logs viser usædvanlig SharePoint-aktivitet 48
   timer før afgang.

### Det de vil have svar på

- Hvor stor er vores reelle externe attack surface?
- Hvor exponerede er vores nøglepersoner online?
- Hvor let er det at lave en plausibel phishing-pretext mod os?
- Hvilke trusselsaktører er relevante for maritime/shipping?
- Kan vores SOC reelt detektere det red-teamet finder?
- Er der spor af eks-medarbejderens data online?

---

## 2. Engagement-objektive og scope

### In-scope

- Domæner: `nordlys-maritime.com`, `nordlys.dk`, `nl-logistics.eu` (+
  alle subdomæner)
- IP-ranges: ASN-block tilhørende Nordlys (skriftligt bekræftet i SOW)
- Cloud-tenants: `nordlysmaritime.onmicrosoft.com`, AWS account
  `123456789012`
- Brand: navn, logo, executive-personae, kundekommunikations-kanaler
- Eks-medarbejderens offentlige fodaftryk (alias kendt af kunden,
  med samtykke-vurdering på etikrunde)

### Out-of-scope

- Aktiv scanning mod skibe (OT/Inmarsat) — kræver klassesselskab + flag-state godkendelse
- Aktiv exploitation af fund — kun rapportering, ikke proof-of-pwn
- Datterselskaber i out-of-scope-jurisdiktioner (kontrollér før hver
  arbejdspakke)
- PII om kunder, leverandører, ansøgere
- Russisk/iransk indhold — kun observation, ingen direkte interaktion
  (sanktionsrisiko)

### Etiske grænser

- **Kun passive opslag.** Brute-force, exploitation og credential stuffing kræver eskaleret SOW-tillæg.
- **Ingen PII i deliverables.** Eks-medarbejderens fund redacteres bag `<details>`.
- **Ingen kunde-/leverandør-data** håndteres eller eksfilteres, heller ikke til "demonstration".
- **Stop-kriterium:** Hvis vi finder live credentials/secrets der er udnyttelige, stopper vi straks, notificerer CISO og overdrager. Vi rapporterer, vi udnytter ikke.

---

## 3. Arbejdspakker

Seks pakker over **6 uger**. Hver pakke er selvstændigt leveringsbar
men bygger ovenpå den foregående.

### Pakke 1 — External Attack Surface Mapping  (uge 1)

**Mål:** Komplet kortlægning af eksterne assets, services, lookalikes.

**Aktiviteter**

- Passiv subdomæne-enumerering via CT-logs, passive DNS, urlscan,
  HackerTarget.
- Tech-stack fingerprinting og live host-probing.
- Cloud-bucket-discovery (S3/GCS/Azure) baseret på brand-aliasser.
- Lookalike-domæne-scan med typo/homoglyph-permutationer.
- Cert-historik-graf: hvilke navne har historisk delt cert med Nordlys.

**Skills**

- `redteam-surface` — primary
- `osint-infrastructure` — pivots og passive DNS

**Recipes**

- `subfinder-passive.sh` — CT + OTX + urlscan + HackerTarget
- `shodan-recon.sh` — `host`, `count`, `facet` for at finde top-porte og org-clustering
- `censys-recon.sh` — `cert`, `web` for cert-historik og webproperty-detaljer
- `dnstwist-wrap.sh` — lookalike-permutationer (direkte koblet til pakke 3)
- `url-recon.sh` — verificér live på hver fundet asset

**Deliverable:** Asset-inventory (CSV + Maltego-graf) + executive
"top 10 mest bekymrende eksponeringer".

---

### Pakke 2 — Brand og Executive OSINT  (uge 2)

**Mål:** Identificér impersonations, måle nøglepersoners eksponering,
forberede C-suite anti-impersonation-playbook.

**Aktiviteter**

- Username-pivot på CEO, CFO, COO, CISO på tværs af 600+ platforme.
- Lookalike-konto-discovery på LinkedIn, X, Facebook, Instagram.
- Reverse image search af officielle profilbilleder (find misbrug).
- AI-content-vurdering af mistænkelig CEO-video der cirkulerer i en
  chatgruppe.
- Breach-check af executive-mailadresser.
- Telefon-OSINT på de numre kunder ringer til ("er det egentlig vores
  nummer?").
- Bevarelse af impersonation-evidens før kontoer kan blive slettet.

**Skills**

- `osint-multi-search` — samlet "person dossier"-tilgang
- `osint-username-search` — alias-pivots
- `osint-social-media` — profiler og opslag
- `osint-image-analysis` — verificér profilbilleder
- `osint-ai-content` — deepfake-/voice-clone-check af CEO-video
- `osint-email-search` — exec-email-eksponering
- `osint-phone-numbers` — kundefacing telefonnumre
- `osint-documentation` — preservation før take-down

**Recipes**

- `username-pivot.sh` — alias på tværs af platforme
- `hibp-check.sh` — `email` mode for hver executive
- `inspect-image.sh` — EXIF + filnavnshints på officielle billeder
- `reverse-search.md` — manuel reverse image search-procedure
- `archive-url.sh` — Wayback + screenshots af alle impersonation-konti
- `audit-hints.sh` — sanity-check at vi ikke har overset metadata-spor

**Deliverable:** "Executive Exposure Report" + impersonation-evidence-
pack (PDF + Wayback-links) + take-down-prioritering.

---

### Pakke 3 — Phishing-readiness og Pretext-research  (uge 3)

**Mål:** Hvor let er det at lave en troværdig phish mod en Nordlys-
medarbejder? **Kun recon — ingen levering af mails.**

**Aktiviteter**

- E-mail-format-discovery (firstname.lastname@, fnachname@, ...).
- Medarbejder-enumerering fra offentlige LinkedIn-profiler (kun navn,
  rolle, afdeling — ingen kontaktdata).
- Breach-data-mapning: hvilke @nordlys-adresser optræder i historiske
  breaches?
- Pretext-research: hvilke verserende sager, kundenavne, projekter
  optræder offentligt (pressemeddelelser, jobannoncer, github-readmes)?
- Lookalike-domæne-tilgængelighed: hvilke typo-domæner kunne en
  attacker registrere?

**Skills**

- `redteam-phishing-recon` — primary
- `osint-email-search` — pivots
- `osint-social-media` — LinkedIn employee-enum

**Recipes**

- `hibp-check.sh` — `domain` mode (offentlig endpoint, ingen credits)
- `dnstwist-wrap.sh` — generer kandidat-lookalikes til registrering
- `subfinder-passive.sh` — secondary pivots på Nordlys-aliasser

**Deliverable:** "Phishing Readiness Score" + 5 konkrete pretext-
scenarier rangeret efter sandsynlighed + liste over typo-domæner
Nordlys selv bør registrere defensivt.

---

### Pakke 4 — Adversary Modeling og Code-leak-scan  (uge 4)

**Mål:** Hvilke trusselsaktører er relevante? Findes der allerede
lækket Nordlys-kode/secrets offentligt?

**Aktiviteter**

- MITRE ATT&CK-mapping af TTPs for maritime/shipping-sektoren
  (kendte aktører: Mustang Panda, FIN-grupper med fakturafraud,
  ransomware-affiliates der targeter shipping).
- CTI-feed-konsolidering: hvad siger åbne kilder om sektoren de
  seneste 12 måneder?
- GitHub-kode-søgning efter Nordlys-secrets, configfiler, IaC.
- Paste-site-scan for Nordlys-nævnelser.
- Darkweb-recon: er Nordlys nævnt på leak-fora, initial-access-broker-
  posts, ransomware-leak-sites?
- Hvis ransomware-wallet er nævnt i forbindelse med sektoren: trace
  on-chain.

**Skills**

- `redteam-ttp` — adversary emulation-modellering
- `redteam-code-leaks` — kode/secret-fund
- `osint-darkweb` — leak-forum-recon
- `osint-multi-search` — bred CTI
- `osint-crypto` — ransomware-wallet-tracing hvis relevant
- `osint-translation` — russisk/kinesisk-sproget CTI

**Recipes**

- `attck-pivot.sh` — `technique`, `group`, `users-of` for sektor-TTPs
- `github-dork.sh` — batch-dorks mod Nordlys-aliasser (kræver
  `GITHUB_TOKEN`)
- `wallet-trace.sh` — hvis krypto-adresser dukker op i CTI
- `translate-cjk.sh` — kinesiske/japanske CTI-posts
- `archive-url.sh` — bevar darkweb-/leak-evidens

**Deliverable:** Threat profile (top 5 aktører + deres TTPs mappet til
Nordlys' overflade) + code-leak-fund (hvis nogen) + sektor-IOC-feed.

---

### Pakke 5 — Defensive Readiness Assessment  (uge 5)

**Mål:** Kan SOC reelt detektere det red-teamet og OSINT har fundet?
Cross-walk fra **fund → detection-coverage → gap**.

**Aktiviteter**

- For hver high-value-finding i pakke 1–4: kan SOC se det? Hvilken
  Sigma-/SPL-/KQL-regel ville fyre? Findes den?
- Log-coverage-audit: er Sysmon konfigureret? Hvilke EventIDs fanges
  i AzureAD-signins? Er CloudTrail aktiveret på relevante regioner?
- Threat-hunting-hypoteser baseret på sektor-TTPs (Pakke 4).
- IR-playbook-review: har de et ransomware-runbook? Kommunikationskæde?
  Forsikring-touchpoint?

**Skills**

- `blueteam-detection` — Sigma + SPL/KQL audit
- `blueteam-hunting` — hypothesis-driven hunts
- `blueteam-logs` — log-coverage gap
- `blueteam-ir` — playbook-review (PICERL-mapping)

**Recipes**

- `attck-pivot.sh` — krydsreferer detections mod ATT&CK-coverage
- `parse-headers.sh` — analyse af modtagne phishing-mails (DMARC/SPF/DKIM)

**Deliverable:** "Detection Coverage Matrix" (TTP × log-source × regel-
status) + 8 Sigma-regler skrevet til deres SIEM + 3 hunt-hypoteser
med konkret SPL-/KQL-query + IR-playbook-redline.

---

### Pakke 6 — Insider-undersøgelse  (uge 6, betinget)

**Mål:** Hvor er den fratrådte medarbejders data — hvis der er noget.
**Etisk:** Kun offentlige kilder, ingen surveillance, redacteret
rapportering. CISO + HR + (i DK) DPO godkender brief før start.

**Aktiviteter**

- Username-pivot på medarbejderens kendte alias (kun det kunden
  oplyser, ingen guess).
- Tjek darkweb-/paste-sites for Nordlys-data + medarbejder-alias.
- Tjek offentlige code-sider for commits med Nordlys-snippets der
  matcher deres opgaver.
- Hvis krypto-adresse er kendt: passive on-chain pivot.
- Bevaring af alle fund med tidsstempler.

**Skills**

- `osint-username-search`, `osint-multi-search`, `osint-darkweb`,
  `osint-crypto`, `osint-documentation`
- *Eskalation:* `osint-image-analysis`/`osint-geolocation` hvis
  medarbejderens offentlige posts har relevante metadata

**Recipes**

- `username-pivot.sh`, `wallet-trace.sh`, `archive-url.sh`
- `inspect-image.sh`, `decode-metadata.sh` — på offentlige
  billeder hvis relevante

**Deliverable:** Faktuelt notat (ikke konklusion om skyldsspørgsmål)
+ evidens-pack med tidsstempler + recommendations til HR/legal.

---

## 4. Tidsplan og milestones

| Uge | Pakke | Milestone |
|---:|---|---|
| 1 | Attack Surface | Asset-inventory + top-10-eksponering |
| 2 | Brand/Exec OSINT | Impersonation-evidens + readiness report |
| 3 | Phishing-readiness | Score + pretext-scenarier + lookalike-liste |
| 4 | Adversary + code-leak | Threat profile + IOC-feed + leak-fund |
| 5 | Defensive readiness | Coverage matrix + Sigma-regler + IR-redline |
| 6 | Insider (betinget) | Notat + evidens-pack |

**Status-cadens:** Tirsdag/torsdag 30-min check-in med CISO. Fredag:
formel ugentlig deliverable + tracker-update. Slut: 2-timers
executive-readout.

---

## 5. Deliverable-format

For hvert deliverable følges Trace Labs write-up-standarden tilpasset
kommerciel kontekst:

- **Executive summary** (1 side, business-vinkel)
- **Findings** (prioriteret efter sværhedsgrad + sandsynlighed)
- **Evidence** (alt redacteret bag spoilers eller i separat encrypted
  vault — aldrig PII i klartekst)
- **Recommendations** (konkrete, prioriterede, med ejer + tidsestimat)
- **Appendix:** rå data, tool-output, kommando-historik (for
  reproducerbarhed)

Sprog: dansk eller engelsk efter kundens ønske (denne kunde: dansk
til executive, engelsk til teknisk appendix).

---

## 6. Tool-coverage matrix

Viser hvor stor en del af toolboxen der reelt aktiveres i engagementet.

### OSINT-skills (15 i alt — 14 dækket)

| Skill | P1 | P2 | P3 | P4 | P5 | P6 |
|---|:-:|:-:|:-:|:-:|:-:|:-:|
| osint-ai-content | | ● | | | | |
| osint-crypto | | | | ● | | ● |
| osint-darkweb | | | | ● | | ● |
| osint-documentation | | ● | | ● | | ● |
| osint-email-search | | ● | ● | | | |
| osint-geolocation | | | | | | ◐ |
| osint-image-analysis | | ● | | | | ◐ |
| osint-infrastructure | ● | | | | | |
| osint-multi-search | | ● | | ● | | ● |
| osint-phone-numbers | | ● | | | | |
| osint-social-media | | ● | ● | | | |
| osint-steganography | | | | | | |
| osint-translation | | | | ● | | |
| osint-username-search | | ● | | | | ● |
| osint-wireless | | | | | | |

*● = primary use, ◐ = betinget. Steganography + wireless ikke aktiveret
i baseline-scope — kunne tilføjes som on-site assessment-tillæg.*

### Red-team-skills (4 i alt — 4 dækket)

| Skill | Pakke |
|---|---|
| redteam-surface | P1 |
| redteam-phishing-recon | P3 |
| redteam-code-leaks | P4 |
| redteam-ttp | P4 |

### Blue-team-skills (4 i alt — 4 dækket, alle i P5)

| Skill | Pakke |
|---|---|
| blueteam-detection | P5 |
| blueteam-hunting | P5 |
| blueteam-ir | P5 |
| blueteam-logs | P5 |

### Recipes (26 i alt — 18 aktivt brugt)

**Aktiv brug:** `subfinder-passive`, `shodan-recon`, `censys-recon`,
`dnstwist-wrap`, `url-recon`, `username-pivot`, `hibp-check`,
`inspect-image`, `archive-url`, `audit-hints`, `attck-pivot`,
`github-dork`, `wallet-trace`, `translate-cjk`, `parse-headers`,
`decode-metadata`, `reverse-search`, `new-writeup` (til
deliverable-templating).

**Ikke brugt i baseline:** `decode-w3w`, `flight-trace`, `geocode`,
`maritime-vessel` (kunne anvendes til skib-tracking-tillæg —
ironisk givet kunden), `qr-decode`, `verify-place`, `wikidata-coords`,
`fetch-challenge`.

**Add-on-mulighed:** `maritime-vessel.sh` + `flight-trace.sh` til
"executive travel pattern OSINT" som separat opt-in arbejdspakke.

---

## 7. Pricing-skelet (estimerede dage)

| Pakke | Senior-dage | Operator-dage |
|---|---:|---:|
| 1 Attack Surface | 2 | 3 |
| 2 Brand/Exec | 1.5 | 3.5 |
| 3 Phishing-readiness | 1 | 2 |
| 4 Adversary + leaks | 2 | 3 |
| 5 Defensive | 3 | 2 |
| 6 Insider (betinget) | 1 | 2 |
| Project mgmt + readout | 2 | 1 |
| **I alt** | **12.5** | **16.5** |

(Konkret pris afhænger af satser og evt. tillæg — ikke en del af denne
spec.)

---

## 8. Hvad sker hvis kunden vil have mere

| Mulig add-on | Skills/Recipes der aktiveres |
|---|---|
| Site security walkthrough (København + Hamburg) | `osint-wireless`, BSSID-mapping, `osint-geolocation` |
| Executive travel risk | `flight-trace.sh`, `maritime-vessel.sh`, `wikidata-coords.sh` |
| Sanktion- og 3.-parts-risk-screening af leverandører | `osint-multi-search` + WHOIS/CT-pivots, `censys-recon` på leverandører |
| Aktiv phishing-simulation | Eskaleret SOW + separat etik/legal-runde |
| OT/maritime-network-assessment (skibe) | Eskaleret SOW + klassesselskab-godkendelse |
| Periodisk monitoring-abonnement | Recipe-pipeline + scheduling |

---

## 9. Etisk og legalt — ufravigeligt

- SOW underskrevet før første query.
- DPIA (GDPR) review af pakke 2 og 6 før start.
- Eks-medarbejder-pakke kræver dansk DPO-greenlight.
- Ingen interaktion med out-of-scope-jurisdiktioner uden separat
  sanktion-screening.
- Alle stop-kriterier fra `.claude/agents/ethics-escalation.md`
  gælder identisk.

---

*Denne spec er en eksempel-skabelon. Kopiér den til et nyt
engagement, udskift kunde/scope/tidsplan, og brug tool-coverage-
matrixen til at vise kunden bredden af det vi leverer.*

# Tilbuds-spec: Danmarks Nationalbank — System til beskyttelse mod fake news

> **Mock-tilbud baseret på reelt udbud.** Udbuds-ID `5cf61ed7-cead-4686-9d7c-56ea7fb997c4`,
> deadline for interessetilkendegivelse 8. juni 2026 kl. 12:00 CEST.
> Køber: Danmarks Nationalbank (DNB), CVR 61092919, kontakt
> `udbud@nationalbanken.dk`. Anslået værdi: 1.500.000 DKK ekskl.
> moms over 4 år (alle optioner inkluderet).
>
> Dette dokument er en skabelon til vores faktiske tilbud — det
> mapper DNB's krav 1:1 mod vores toolbox og adresserer det
> kritiske "standardsystem"-krav ærligt.

---

## 1. Resumé

Vi tilbyder **BrandVagten** — en managed brand-protection-service for
Danmarks Nationalbank. Servicen kombinerer en kuratoret stak af
markedsledende OSINT-værktøjer med dansktalende analytiker-bemanding,
der overvåger misbrug af DNB's identitet på tværs af web, sociale
medier, annonce-platforme og domæne-/cert-økosystemet — og driver
take-down-anmodninger gennem dokumenterede kanaler.

Servicen er **driftsklar fra dag 14** efter kontraktindgåelse, kræver
**ingen integration** med Nationalbankens IT, og leveres som en
periodisk abonnementsservice med klar adskillelse mellem initiale
omkostninger, løbende abonnement og take-down-overforbrug.

---

## 2. Forståelse af opgaven

DNB efterspørger to kernefunktioner:

1. **Overvågning og overblik** over annoncer, websider og platforme der
   misbruger DNB's eller ledelsens identitet (navn, billeder, logoer)
   til falske påstande om bankens virke, dansk økonomi eller fiktive
   samarbejdsrelationer/produkter.
2. **Effektiv anmeldelse og take-down** hos platforme, hostingudbydere
   og lignende.

Med periodevis til-/fravalg af coverage på (a) DNB selv vs.
(b) ledende medarbejdere, og separat prissætning af eventuelt
ledelses-tillæg.

Eksplicit kravspecifikation til løsningen:

- "Eksisterende og velafprøvet standardsystem" — minimal tilpasning
- "Ingen integration med Nationalbankens IT-systemer"
- Pris struktureret som: (1) initial, (2) løbende abonnement,
  (3) ekstra-takedowns over inkluderet kvota
- Ufravigelige vilkår: 30 dages betaling fra korrekt faktura;
  Nationalbankens navn/logo må kun bruges som simpel reference efter
  skriftlig aftale; DNB medvirker ikke i markedsføring

---

## 3. Vores løsning: BrandVagten

### 3.1 Arkitektur i tre lag

```
┌─────────────────────────────────────────────────────────────┐
│  Lag 3: Take-down-execution                                 │
│  Analytiker-drevet workflow → registrars, hostere,          │
│  platforme, ad-netværk, app-stores                          │
├─────────────────────────────────────────────────────────────┤
│  Lag 2: Triage og evidens                                   │
│  Dansk OSINT-team: confidence-scoring, evidens-pack,        │
│  redacted rapportering, dialog med DNB                      │
├─────────────────────────────────────────────────────────────┤
│  Lag 1: Continuous detection                                │
│  • Domæne-/cert-overvågning (CT-logs, dnstwist, urlscan)    │
│  • Social media: Meta, X, TikTok, YouTube, LinkedIn         │
│  • Annonce-overvågning: Meta Ad Library, Google Ads,        │
│    TikTok Ad Library                                        │
│  • Reverse image search på DNB-logo og executive-portrætter │
│  • App-stores: Apple, Google                                │
│  • Phishing-/fake-site-feeds: PhishTank, urlscan, OpenPhish │
│  • AI-content-detektion: deepfake, voice-clone, GAN-faces   │
└─────────────────────────────────────────────────────────────┘
```

Lag 1 er **automatiseret**, kører kontinuerligt og kuraterer signaler.
Lag 2 er **menneske-drevet** — det er her DNB får værdien af et team
der ved hvad Nationalbanken er, og kan vurdere kontekst (er en post
satire, kritik eller reelt misbrug?). Lag 3 er **proces-drevet** med
forberedte template-anmodninger til hver platform.

### 3.2 "Standardsystem" — vores fortolkning

DNB beder om et "eksisterende og velafprøvet standardsystem". Vi
fortolker det som: en **driftsklar service med veldokumenteret
workflow**, ikke et hyldeprodukt-stykke software. Vores stak består
af industri-standard værktøjer (Censys, Shodan, urlscan.io,
dnstwist, Wayback Machine, Meta Ad Library, Google Ad Transparency
Center, m.fl.) og en operations-platform der har kørt i produktion
hos andre kunder.

**Hvad DNB får:** en konfigureret, dokumenteret, driftsklar service.
**Hvad DNB ikke får:** en SaaS-portal hvor DNB selv klikker. Al
betjening sker via vores dansktalende team og en delt incident-/
rapport-portal.

Vi adskiller os fra rene produktudbydere (ZeroFox, Recorded Future
Brand Intelligence, BrandShield) ved at **levere analyst-as-a-service**
oveni — relevant for en kunde i DNB's størrelse hvor licens-overhead
af enterprise-produkter ofte overstiger den faktiske trussel-volumen.

---

## 4. Funktionel dækning vs. DNB's krav

### Krav 1: Overvågning og overblik

| Misbrugs-type | Detection-metode | Tools/skills i vores stak |
|---|---|---|
| Lookalike-domæner (`nationalbankan.dk`, `nationalbank-dk.com`) | Dnstwist-permutationer + CT-overvågning + nytregistrerede domæner-feeds | `dnstwist-wrap.sh`, `censys-recon.sh cert-search`, `subfinder-passive.sh` |
| Falske websider der efterligner nationalbanken.dk | URL-recon + visuel sammenligning + screenshot-diff | `url-recon.sh`, `archive-url.sh`, manuel review |
| Falske annoncer (Meta, Google, TikTok) | Søgning i offentlige ad-libraries på DNB-navne + executive-navne | Meta Ad Library API, Google Ad Transparency Center, TikTok Ad Library |
| Fake sociale profiler (X, LinkedIn, Facebook, Instagram, TikTok, Telegram) | Username-pivot + manual review af nye matches | `username-pivot.sh`, `osint-social-media`, `osint-username-search` |
| Misbrug af DNB-logo i billeder/videoer | Reverse image search på officielle assets, branded watermark-tracking | `osint-image-analysis`, `inspect-image.sh`, Google Lens, Yandex |
| AI-genereret indhold (deepfake af nationalbankdirektøren) | Detektor-stack: GAN-face, deepfake-video, voice-clone, C2PA-check | `osint-ai-content` |
| Phishing-sites der claimer DNB-tilknytning | Phishing-feeds + cert-overvågning + URL-recon | `redteam-phishing-recon`, urlscan.io, OpenPhish, PhishTank |
| Fake apps i App Store / Google Play | Periodisk søgning på navne + visuel review | Apple App Store API, Google Play scraping (ToS-konform) |
| Fake news-artikler der citerer DNB falsk | Mediekildér: GDELT, Google News, danske medie-monitorering | Multi-source feed-aggregation |
| Krypto-scams der claimer DNB-blåstempling | Krypto-OSINT, wallet-tracing | `osint-crypto`, `wallet-trace.sh` |
| Trussels-aktør-attribution | TTP-mapping mod kendte impersonation-kampagner | `redteam-ttp`, `attck-pivot.sh` |
| Evidens-bevaring (før take-down) | Snapshot + Wayback + hash-chain | `osint-documentation`, `archive-url.sh` |

**Coverage-rytme:**
- **Realtid (≤15 min):** nyregistrerede lookalike-domæner, nye certs i CT-logs der matcher watchlist
- **Hver time:** sociale medier-monitor (priorityord), nye phishing-URLs
- **Hver 4. time:** annonce-libraries
- **Dagligt:** app-stores, reverse image search-revisit, fake news-feeds
- **Ugentligt:** krypto-monitor, dybere darkweb-recon

### Krav 2: Take-down-værktøj

Take-down-eskalation kører gennem en fast workflow med veldokumenterede
template-pakker per kanal:

| Kanal | Take-down-vej | Typisk SLA |
|---|---|---|
| Domain registrar | Abuse-rapport + UDRP-eskalering for trademark | 24-72 timer for abuse, 30-60 dage for UDRP |
| Hosting provider | `abuse@` med komplet evidens-pack | 24-48 timer |
| Cloudflare/CDN | Reverse-proxy-aftagelse + origin-hosting | 24 timer |
| Meta (FB/IG) | Brand Rights Protection-portal | 24-72 timer |
| X (Twitter) | Trademark/impersonation-form | 48-72 timer |
| TikTok | IP Protection-portal | 24-72 timer |
| YouTube | Trademark / impersonation-form | 24-72 timer |
| LinkedIn | Help-form for impersonation | 24-72 timer |
| Apple App Store / Google Play | Trademark-form per platform | 7-14 dage |
| Google/Meta-annoncer | Ad reporting + brand-bidding-eskalering | 24-48 timer |
| Phishing-URLs (browser-warning) | Google Safe Browsing, MS SmartScreen | 24-48 timer |

For hver take-down leverer vi: dato/tid, kanal, sagsnummer hos
modtageren, evidens-pack-reference, status og udfald. Alt logges i
delt portal og månedlig rapportering.

---

## 5. Service-model og SLA

### 5.1 Roller og bemanding

- **Senior service manager** (kontaktperson DNB) — 0,1 FTE
- **Lead analytiker** (dansk, OSINT-baggrund, sektorkendskab) — 0,3 FTE
- **OSINT-analytikere** (rotation, 24/5-dækning) — 0,5 FTE
- **Take-down-koordinator** — 0,2 FTE (skalér ved spike)
- **AI/automation-engineer** (vedligehold af detection-pipeline) — 0,1 FTE

Total ~1,2 FTE baseline. Skalérbar.

### 5.2 SLA-måltal

| Metric | Mål |
|---|---|
| Detection → triage (P1 high-impact) | ≤ 2 timer i kontortid, ≤ 6 timer udenfor |
| Detection → take-down-indsendt | ≤ 24 timer for klar-cut sager, ≤ 72 timer for komplekse |
| Confidence-score for rapporterede fund | ≥ 80 % på "konfirmerede" sager |
| False-positive-rate | ≤ 10 % over rullende 90-dages vindue |
| Månedsrapport | 5. arbejdsdag i efterfølgende måned |
| Kontorpåtale-respons | ≤ 4 timer i kontortid (mandag-fredag 08-17) |

Akut-eskalering (fx live deepfake-video af DNB-direktøren i en
finansiel pump-and-dump): dedikeret hotline med 1-times-respons.

### 5.3 Leverancer

- **Real-time portal** med alle åbne sager, status, evidens-links
- **Ugentlig executive-rapport** (1 side) med trend, top-5 sager, take-down-rate
- **Månedlig dybde-rapport** med trussels-landskab, sektor-trends,
  recommendations
- **Kvartalsvis strategi-session** (90 min) med DNB om
  trussels-evolution og defensive prioriteringer
- **Annual review** med KPI-gennemgang og scope-justering

---

## 6. Optioner: scope-modulering

### Option A — Kun Nationalbanken (baseline)

Overvågning af identitet, navn, logo og brand for selve institutionen
Danmarks Nationalbank. Standard-watchlist:

- Navne: "Nationalbanken", "Danmarks Nationalbank", "Danish Central Bank",
  "Danish National Bank", "Nationalbanken DK", "DNB" (med disambiguation)
- Domæner: `nationalbanken.dk`, `dnb.dk`, evt. internationale aliasser
- Visuelle assets: officielt logo (vektor + raster i flere størrelser),
  bygningens facade Langelinie Allé 47, evt. interiør-billeder fra
  pressefotos
- Officielle social-konti

### Option B — Inklusiv ledende medarbejdere

Tillæg der udvider watchlisten til ledelsen. Standard-omfang:

- Nationalbankdirektøren (formand for direktionen)
- Vice-direktører i direktionen
- Bestyrelsesmedlemmer (offentligt kendte)
- Repræsentantskab — kun de offentligt aktive (formand m.fl.)

Per person tilføjes:
- Navn-variationer + titler
- Offentlige profilbilleder (pressekvalitet)
- Officielle social-konti (LinkedIn, X, hvis relevant)
- Reverse image search-overvågning af portrætter

Tillægget kan **periodevis aktiveres/deaktiveres** med 30 dages
varsel (passer ift. valgsituationer, mediestorm-perioder,
internationale møder).

---

## 7. Prisstruktur (DNB's tre-deling)

> Konkrete kroner-tal i tilbuddet justeres efter endelig licens-aftale
> med 3.-parts feeds og endelig FTE-allokering. Intervallerne herunder
> er kalibreret efter udbuddets anslåede værdi på 1,5 mio DKK over
> 4 år (~375 t. DKK/år).

### 7.1 Initiale omkostninger (engangs)

| Element | Estimat |
|---|---|
| Onboarding-workshop (½ dag hos DNB) | inkluderet |
| Baseline-scan af eksisterende misbrug (måned 0) | inkluderet |
| Watchlist-opsætning + executive-profil-indsamling | inkluderet |
| Detection-pipeline-konfiguration | inkluderet |
| Portal-onboarding for 5 DNB-brugere | inkluderet |
| **I alt initial** | **0 — eller flat 45-75 t. DKK** |

(Vi har normalt 0-initial-model — alt aktiveret indenfor 14 dage.
Hvis DNB ønsker bredere onboarding kan vi pris-sætte separat.)

### 7.2 Løbende abonnement

| Tier | Indhold | Pris/år (estimat) |
|---|---|---|
| **Option A** (kun DNB) | Detection alle kanaler + 50 take-downs/år + ugentlig rapport + portal | 240-300 t. DKK |
| **Option B** (DNB + ledelse, ~8-12 personer) | A + executive-coverage + 30 ekstra take-downs/år (80 total) | +60-100 t. DKK/år |
| **Total A+B** | | **300-400 t. DKK/år** |

Over 4 år: 1,2-1,6 mio DKK — passer indenfor udbuddets ramme.

### 7.3 Ekstraudgifter ved overforbrug af take-downs

| Take-down-kompleksitet | Pris per take-down |
|---|---|
| Standard (platform-rapport, klar evidens) | 1.500-2.500 DKK |
| Kompleks (registrar-eskalering, multi-platform) | 4.000-6.000 DKK |
| UDRP / juridisk eskalering | 12.000-18.000 DKK + WIPO-gebyr |

Take-downs bookes mod kvota først; overforbrug faktureres månedligt
specificeret. DNB modtager varsel når 80 % af kvota er forbrugt.

---

## 8. Overholdelse af ufravigelige vilkår

| Vilkår fra DNB | Vores håndtering |
|---|---|
| Betaling 30 dage fra korrekt faktura | Bekræftet — vores standard er 30 dage netto. |
| Navn/logo/bygning kun som simpel reference efter skriftlig aftale | Bekræftet — DNB tilføjes ikke til reference-liste, case studies eller pressemateriale uden eksplicit skriftlig samtykke. |
| DNB medvirker ikke i markedsføring | Bekræftet — ingen co-marketing, ingen pressemeddelelser ved kontraktindgåelse, ingen logo-brug på vores website. |

---

## 9. Tidsplan og leverancer

| Uge | Aktivitet | Leverance |
|---|---|---|
| -1 | Kick-off + scope-bekræftelse | SOW underskrevet |
| 1 | Watchlist-opsætning, executive-profilindsamling (hvis option B), 3.-parts-feed-konfiguration | Watchlist-dokument til DNB-review |
| 2 | Baseline-scan, første triage-runde | "Baseline brand abuse report" + portal-onboarding |
| 3 | Detection-pipeline live, første take-downs aktiveret | Servicen i drift — første ugentlige rapport |
| 4-12 | Kontinuerlig drift, første kvartalsmøde i uge 12 | Ugentlige + månedsrapport |
| 13 | Q1 review + scope-justering | Q1-rapport + KPI-readout |
| Løbende | Månedlig rapportering, kvartalsmøder, årlig strategisession | Standard service-cadens |

**Driftsklarhed: dag 14** efter kontraktindgåelse. Baseline-scan
leveres dag 21 — så DNB ser umiddelbar værdi fra slut af måned 1.

---

## 10. Risici og forbehold

**Vi er ærlige om følgende:**

1. **Standardsystem-fortolkning.** Vi er ikke en SaaS-leverandør i
   klassisk forstand. Vi leverer en operations-service med
   industri-standard værktøjer + ekspertbemanding. Hvis DNB strikt
   tolker "standardsystem" som hyldeprodukt med selvbetjenings-UI,
   anbefaler vi at se på rene produkt-udbydere parallelt.

2. **Coverage af lukkede platforme.** Telegram-grupper, lukkede
   Discord-servere, WhatsApp-grupper og dele af darkweb er per
   definition svære at monitere systematisk. Vi monitorer det vi
   etisk og legalt kan, og rapporterer hvad vi finder via partnerskaber
   og åbne kilder.

3. **Take-down-rate er ikke 100 %.** Realistisk take-down-rate ligger
   på 75-90 % indenfor 30 dage afhængigt af platform. Resterende sager
   kræver juridisk eskalering eller forbliver åbne. Vi rapporterer
   ærligt på rate per platform.

4. **Annonce-coverage er platform-afhængig.** Meta Ad Library, Google
   Ad Transparency Center og TikTok Ad Library er offentlige og
   dækkes systematisk. Native-ad-netværk og programmatic-ads er
   sværere — vi gør hvad vi kan via sample-scraping og rapportering
   fra brugere.

5. **AI-content-detection er probabilistisk.** Deepfake-detektorer
   har false-positive- og false-negative-rates. Vi rapporterer altid
   med confidence-score og menneskelig review — aldrig automatisk
   take-down på AI-detection alene.

---

## 11. Tool-coverage matrix

Hvor stor en del af vores toolbox aktiveres i BrandVagten-servicen:

### OSINT-skills (15 i alt — 12 aktivt brugt)

| Skill | Brug |
|---|---|
| `osint-ai-content` | ● Deepfake/voice-clone-detection af exec-video/audio |
| `osint-crypto` | ● Krypto-scam-attribution når DNB nævnes |
| `osint-darkweb` | ● Periodisk recon for DNB-impersonation på fora |
| `osint-documentation` | ● Evidens-pack for hver take-down |
| `osint-email-search` | ● Spear-phishing-domain-detection mod DNB-medarbejdere |
| `osint-image-analysis` | ● Logo/portræt-misbrug via reverse image search |
| `osint-infrastructure` | ● Phishing-/fake-site-attribution |
| `osint-multi-search` | ● Sammensæt impersonation-dossiers |
| `osint-social-media` | ● Kerne-detection-kanal |
| `osint-translation` | ● Internationale impersonations (russisk/kinesisk/tysk) |
| `osint-username-search` | ● Executive-profil-overvågning |
| `osint-phone-numbers` | ◐ Hvis fake-call-center claimer DNB-tilknytning |
| `osint-geolocation` | – Ikke i baseline |
| `osint-steganography` | – Ikke i baseline |
| `osint-wireless` | – Ikke i baseline |

### Red-team-skills (4 i alt — 2 aktivt brugt defensivt)

| Skill | Brug |
|---|---|
| `redteam-phishing-recon` | ● Defensivt: forudse hvilke pretexts attackers bruger mod DNB |
| `redteam-ttp` | ● TTP-mapping mod kendte bank-impersonation-kampagner |
| `redteam-surface` | ◐ Periodisk attack-surface review som add-on |
| `redteam-code-leaks` | – Ikke relevant for brand-protection-scope |

### Blue-team-skills (4 i alt — 1 aktivt brugt)

| Skill | Brug |
|---|---|
| `blueteam-ir` | ● IR-koordinering ved akut impersonation-storm |
| `blueteam-detection` | – DNB har egen SIEM |
| `blueteam-hunting` | – DNB har eget team |
| `blueteam-logs` | – DNB har eget team |

### Recipes (26 i alt — 14 aktivt brugt)

`dnstwist-wrap.sh` (kerne), `subfinder-passive.sh`,
`shodan-recon.sh`, `censys-recon.sh` (CT-logs er kritiske),
`url-recon.sh`, `archive-url.sh` (evidens-bevaring),
`username-pivot.sh`, `inspect-image.sh`, `parse-headers.sh`
(phishing-mail-analyse), `attck-pivot.sh`, `wallet-trace.sh`,
`hibp-check.sh` (executive-breach-baseline), `reverse-search.md`,
`audit-hints.sh`.

---

## 12. Næste skridt

1. **Interessetilkendegivelse** sendes til `udbud@nationalbanken.dk`
   senest 8. juni 2026 kl. 12:00 CEST.
2. Hvis DNB inviterer til dialog: 90-min møde med teknisk demo af
   detection-portal, eksempel-rapporter fra anonymiserede sager,
   diskussion af scope-modulering.
3. Reference-call med 1-2 sammenlignelige kunder (kun efter samtykke
   fra reference-kunden).
4. Tilbud konkretiseres med kroner-præcis pris, endelig SLA-formulering
   og kontraktudkast.

---

## 13. Bilag

- **B1** — Beskrivelse af 3.-parts feeds og licens-status
- **B2** — Reference-arkitektur diagram (PNG)
- **B3** — Eksempel-månedsrapport (anonymiseret)
- **B4** — SLA-bilag med præcise definitioner og målepunkter
- **B5** — DPIA-skabelon (executive-coverage involverer behandling
  af offentligt tilgængelige PII om identificerede personer —
  GDPR art. 6 stk. 1 litra f, legitim interesse)
- **B6** — Beredskab ved leverandørskift / exit-plan

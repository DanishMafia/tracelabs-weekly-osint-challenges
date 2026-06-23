# Option B — Executive Coverage Pilot

> **Forlængelse af baseline-scanningen** — denne sektion dækker
> Option B (jf. tilbudsspec §6): overvågning af DNB's offentligt
> kendte ledende medarbejdere. Scanning gennemført 2026-05-27
> ca. 19:20–19:45 UTC umiddelbart efter baseline-scan.
>
> **Etisk ramme:** Kun **offentligt kendte personer i public-facing
> roller**, kun **passive OSINT** mod offentligt tilgængelige kilder,
> **ingen privat-data** inkluderet i rapport selv hvor det er offentligt
> publiceret. Stop-kriterier fra
> `.claude/agents/ethics-escalation.md` gælder.

---

## 1. In-scope: identificerede public-facing roller

Hentet fra DNB's egen offentlige sitemap
(`https://www.nationalbanken.dk/sitemap_content.xml`):

### Direktion (primær Option B-scope)

| Rolle | Navn | Tiltrådt | Public profile-side |
|---|---|---|---|
| Nationalbankdirektør, kgl. udnævnt formand | Christian Kettel Thomsen | 1. februar 2023 | `/da/om-os/direktion-koncernledelse-og-afdelinger/christian-kettel-thomsen` |
| Vicedirektør | Signe Krogstrup | 2020 | `/.../signe-krogstrup` |
| Vicedirektør | Ulrik Nødgaard | 15. august 2024 | `/.../ulrik-noedgaard` |

### Repræsentantskab og bestyrelse (sekundær scope)

Identificeret men ikke individuelt scannet i denne pilot — relevant
ved fuld Option B-aktivering. Inkluderer (uddrag fra DNB's officielle
side):

- Folketingsmedlemmer udpeget til repræsentantskabet
- Akademiske repræsentanter (Professor Christian Schultz, Philipp Schr…)
- Erhvervsledere (CEO Novo Nordisk og lignende offentlige roller)
- Departementschefer og lignende civil-service ledere

I alt ~24 navne. Anbefaling: ved fuld Option B aktiveres watchlist
trinvis efter risk-eksponering (direktion uge 1, Folketing uge 2,
øvrige uge 3).

---

## 2. Officielle kanaler — verificeret

| Platform | Officiel kanal | Verifikations-signal |
|---|---|---|
| Hjemmeside | `https://www.nationalbanken.dk` | DV-cert, EuroDNS NS, EV i historik |
| LinkedIn | `linkedin.com/company/danmarks-nationalbank` | HTTP 200, "Danmarks Nationalbank \| LinkedIn" titel |
| Bluesky | `@nationalbanken.dk` | **Domain-handle = best practice** (110 posts, 1692 followers, oprettet 2024-11-19) |
| X (Twitter) | Status **uafklaret** | Se §4 — vi kan ikke verificere passivt |
| Facebook / Instagram | Ikke fundet i pilot | DNB linker ikke fra egen side |
| Mastodon | Ikke fundet | — |

**Bemærkelsesværdigt:** DNB's egen hjemmeside (forside, om-os,
kontakt-side) har **ingen synlige links til sociale medier**.
Det er enten en bevidst kommunikationspolitik (minimer
SoMe-engagement) eller et reelt hul i deres kanal-strategi. Som
brand-protection-leverandør anbefaler vi at DNB **eksplicit
publicerer** liste over deres officielle kanaler — det giver
borgere og medier en autoritativ reference til at skelne ægte fra
fake konti.

---

## 3. Fund — handle-grabs på Bluesky

Bluesky's offentlige API tillader passiv profil-opslag. Vi fandt
to konti med handles der matcher DNB's interne shortcodes for
direktion:

### 3.1 `nodgaard.bsky.social`

| Felt | Værdi |
|---|---|
| Handle | `nodgaard.bsky.social` |
| Display name | (tom) |
| Description | (tom) |
| Created | **2024-11-13** |
| Posts | 0 |
| Followers | 5 |

**Risk-vurdering:** MEDIUM.

Konteksten der gør det relevant: Ulrik Nødgaard tiltrådte som
vicedirektør i DNB **15. august 2024** — kun **3 måneder før**
denne handle blev claimed. Det kan være:

1. Ulrik Nødgaard selv (defensiv registrering — så DNB skal
   verificere internt)
2. En anden person ved navn Nødgaard
3. En attacker der har grabbed handle for fremtidig brug

Tomt indhold + nyhed efter rolle-tiltrædelse er et klassisk
**reservation-pattern**. Vi anbefaler: DNB bekræfter ejerskab; hvis
ikke DNB-ejet, monitorér for content-aktivitet og overvej take-down-
anmodning ved misbrug.

### 3.2 `ckth.bsky.social`

| Felt | Værdi |
|---|---|
| Handle | `ckth.bsky.social` |
| Display name | "Kiriya" |
| Description | (tom) |
| Created | 2024-02-07 |
| Posts | 0 |
| Followers | 0 |

**Risk-vurdering:** LAV.

`ckth` er nationalbankdirektør Christian Kettel Thomsens **interne
DNB-shortcode** (synligt i profilbilledets URL: `ckth-kvadrat.jpg`).
Display name "Kiriya" er sandsynligvis et japansk/anime-relateret
brugernavn — dvs. en tilfældig person ikke en rettet impersonation.
Men handle er nu **taget**, så DNB kan ikke selv claime det. Lav-impact.

### 3.3 `dnb.bsky.social`

| Felt | Værdi |
|---|---|
| Handle | `dnb.bsky.social` |
| Display name | "dephne" |
| Created | 2023-11-19 |
| Posts | 246 |
| Followers | 12 |

**Risk-vurdering:** LAV.

Persona-konto, ikke DNB-relateret. Det kortere handle `dnb` er taget,
men DNB har valgt det stærkere domain-baserede handle
`@nationalbanken.dk` — så reelt ingen risk.

### 3.4 Ikke-grabbed (det DNB stadig kan claime)

Disse Bluesky-handles findes IKKE og er stadig tilgængelige for DNB
defensiv registrering:

- `christiankettelthomsen.bsky.social`
- `cketthomsen.bsky.social`
- `krogstrup.bsky.social`
- `signekrogstrup.bsky.social`
- `skrogstrup.bsky.social`

**Anbefaling P0:** DNB registrerer disse 5 alias-handles
**i dag** (Bluesky-handles er gratis). Plus `ulrik-nodgaard.bsky.social`,
`signe-krogstrup.bsky.social`. Total cost: 0 DKK, tidsforbrug: 30 min.

---

## 4. X (Twitter) — verifikations-blind spot

X serverer en client-rendered SPA der returnerer HTTP 200 og
samme HTML-størrelse (~270 KB) for **både eksisterende og
ikke-eksisterende handles**. Vi kan derfor ikke verificere fra
passive HTTP-opslag om følgende handles eksisterer som ægte profiler:

- `x.com/nationalbanken`
- `x.com/danmarksnationalbank`
- `x.com/danishnatbank`
- `x.com/dnb_dk`

**Begrænsning af passiv recon:** En reel BrandVagten-service ville
løse dette med:

1. X API v2 (paid, ~$100-200/mdr for basic search) — direkte query
2. Browser-automation gennem dedikeret recon-rig (ej i denne pilot)
3. Google-/Bing-cache-fallback for OG-tags

For en attacker er X stadig den mest skalérbare kanal til CEO-fraud
og market-manipulation-pretexting. Anbefaling: prioritér X API-licens
i fuld BrandVagten-aktivering.

---

## 5. Pretexting-eksponering — DNB selv som kilde

**Mest kritiske observation i denne Option B-pilot:**

DNB's egne offentlige profilsider for direktion publicerer detaljerede
biografiske oplysninger — fødselsdato, ægteskab, antal og fødselsår
af børn, uddannelses-detaljer, karriereforløb, tidligere stillinger.

Det er **gyldigt informeret offentligt embede** og lever op til
gennemsigtighedsforventninger til en offentlig institution. Men det
er samtidig et **rigt grundlag for social engineering pretexting**:

- En attacker der ringer som "fra HR-juridisk afdeling" kan referere
  præcist til ægtefælle-navn, børn, fødselsdage
- En fake video-/voice-clone-call kan kalibreres med korrekt
  alder-/baggrund-referencer
- En spear-phishing-mail kan inkludere familiemedlems-information
  for at virke insider

**Vi inkluderer IKKE de specifikke detaljer i denne rapport** —
de er kun nævnt i kategoriform. Hvis du vil have specificeret
nøjagtigt hvilke datapunkter, kan vi levere en separat redacted
appendix til intern DNB-cirkulation, ikke til ekstern transmission.

**Anbefaling P1 (kritisk):**

1. DNB kommunikationsafdeling reviewer profilsiderne for
   minimum-publication-need. Forslag: redact ægtefælle-navn (uden
   at fjerne "gift"-status), redact præcise børne-fødselsår, behold
   karriereforløb.
2. Direktion + repræsentantskab modtager træning i pretexting-
   awareness — specifikt: "alt på din DNB.dk-profil er offentligt
   og vil blive brugt mod dig i social engineering".
3. SOC etablerer **synthetic phishing-test** baseret på publiceret
   biografisk data for at måle reel pretexting-modstand.

---

## 6. AI-content (deepfake/voice clone) — initialscan

### urlscan-søgninger

Ingen offentlige scans der indeholder kombinationen af
direktionsnavne + "deepfake" / "scam" / "fake" på urlscan.io:

```
"Christian Kettel Thomsen deepfake"   → 0 matches
"Signe Krogstrup scam"                → 0 matches
"Ulrik Nødgaard fake"                 → 0 matches
"Nationalbanken scam"                 → 0 matches
```

**Vurdering:** Ingen kendt aktiv deepfake-/scam-kampagne mod DNB-
direktionen i offentligt indekseret indhold (per 2026-05-27).
Det er et **positivt** finding — DNB er ikke aktivt mål for synlig
AI-content-misbrug lige nu.

**Begrænsning:** urlscan.io scanner kun sider folk har submittet.
Vi har ikke i denne pilot scannet:

- YouTube (videosøgning kræver enten YouTube API eller browser-search)
- TikTok ad-library
- Telegram-kanaler
- Russiske / kinesiske ad-tech-feeds
- Crypto-scam-fora

Dette dækkes i fuld Option B med ad-library-monitor og
deepfake-detector-pipeline (`osint-ai-content`-skill + tredjeparts
detection-feeds).

---

## 7. Bekræftede positive findings

Det er ikke kun risici — pilot-scanningen viste **stærke
defensive elementer**:

✓ **Ingen breaches** for `@nationalbanken.dk` i HIBP-database
✓ **Domain-handle på Bluesky** — bedste praksis, vanskelig at impersonere
✓ **Cert-historik renheld** — ingen mistænkelige nyudstedelser
   af certs for DNB-domæner (jf. baseline-scan §1)
✓ **Defensiv domain-portefølje** — 22+ TLD'er på fælles Azure-instans
✓ **Minimal SoMe-eksponering** — færre kanaler = færre angrebsflader
✓ **Ingen kendt impersonations-kampagne** mod direktion på offentlige
   feeds
✓ **Konsistent SPF deny + null MX** — defensiv anti-spoofing-config

DNB's overordnede brand-defensive posture er **væsentligt over
gennemsnittet** for sammenlignelige institutioner.

---

## 8. Prioriterede anbefalinger (Option B-specifik)

| # | Handling | Estimat | Risk-impact |
|---|---|---|---|
| **P0** | Claim 5-7 Bluesky-alias-handles for direktion (`krogstrup.bsky.social` m.fl.) | 0 DKK, 30 min | Forhindrer reservation-pattern |
| **P1** | Redact-review af biografi-info på direktion-profilsider — fjern ægtefælle-navne, præcise børn-årgange | <1 dag DNB-internt | Reducerer pretexting-overflade |
| **P2** | Pretexting-awareness-træning for direktion + repræsentantskab baseret på publiceret biografi-data | <2 dage | Strukturel reduktion af social engineering-succes |
| **P3** | DNB publicerer offentligt liste over officielle SoMe-kanaler (LinkedIn + Bluesky + evt. X) — så borgere/medier kan verificere | 1 time | Klar autoritativ reference, gør impersonation lettere at modbevise |
| **P4** | DNB bekræfter status for `nodgaard.bsky.social` — DNB-ejet eller andet? Hvis andet: monitor for aktivering | 1 time | Lukker uafklaret reservation |
| **P5** | DNB bekræfter eller claimer X-handles (`nationalbanken`, `danmarksnationalbank`, etc.) — vores passive recon kan ikke verificere | 1 time | Lukker X verifikations-blind spot |
| **P6** | Synthetic phishing-test baseret på pretexting-templates afledt af DNB's offentlige bio-data | 1-2 uger | Måler reel pretexting-modstand |
| **P7** | Aktivér continuous Option B-monitoring i BrandVagten-service for at fange fremtidige handle-grabs på direktion-aliasser | Inkluderet i Option B-abonnement | Strukturel |

---

## 9. Tools brugt — Option B

| Tool/recipe | Brug i Option B | Status |
|---|---|---|
| `osint-username-search` skill + `username-pivot.sh` | Alias-scan på 600+ platforme | ✓ Kørt på 11 handles |
| `osint-social-media` skill | Officielle kanal-verifikation | ✓ |
| `osint-image-analysis` (indirekte) | Officielle profilbilleder identificeret med URL+hmac | ✓ |
| `osint-multi-search` skill | DNB sitemap-traversal + person-identifikation | ✓ |
| `osint-email-search` skill | HIBP domain-check | ✓ Ingen breaches |
| `osint-ai-content` skill | Deepfake/scam-keyword-søgning | ✓ Negativt fund (= positivt for DNB) |
| `urlscan-check.sh` (ny) | Brand + person-search | ✓ |
| Bluesky public API (direct) | Handle-eksistens + profil-metadata | ✓ Stærkt signal |
| Direct DoH | DNS for SoMe-domæner | ✓ |
| LinkedIn (passiv HTTP) | Officiel side eksistens | ✓ |
| X / Twitter | Profil-verifikation | ✗ Blind spot (SPA) |
| YouTube / TikTok / Telegram | AI-content-search | ✗ Ikke-passive — kræver API |

---

## 10. Næste skridt

1. **DNB kvalitetssikrer fundene** — særligt bekræft eller afkræft
   ejerskab af `nodgaard.bsky.social` og `ckth.bsky.social`.
2. **P0-anbefaling implementeres i dag** — defensiv claim af de 5-7
   tilgængelige Bluesky-handles (zero cost, høj symbolsk værdi).
3. **P1 + P2** kræver intern DNB-koordinering (kommunikation +
   sikkerhed + HR).
4. **Fuld Option B-aktivering** i BrandVagten-service åbner:
   - Continuous Bluesky/X/LinkedIn-monitor på alle direktion-alias
   - Daglig AI-content-scan via integrerede deepfake-detection-feeds
   - Repræsentantskab tilføjes watchlist trinvis
   - Real-time alarmering ved nye registreringer af lignende handles

---

## Etisk efterord

Denne rapport indeholder **kun rolle-relevant information** om
offentligt kendte personer i public-facing embeder i en offentlig
institution. **Privat-data fra DNB's eget offentlige indhold er
bevidst ikke inkluderet**, selv hvor det ville understøtte pretexting-
risikoargumentet kvantitativt.

Det betyder også at hvis nogen modtager rapporten og finder den
"tynd" på det punkt, er det **intentionelt**. En reel rapport til
DNB kan indeholde redacted appendix til intern brug — men aldrig
til ekstern publicering.

Vi har **ikke kontaktet, DM'et eller interageret med** nogen af de
fundne konti. Vi har **ikke besøgt** mistænkelige domæner i browser.
Vi har **ikke** lavet reverse image search på personbilleder (det er
en aktiv kanal og bør først ske som del af betalt engagement med
brand-owner authorization).

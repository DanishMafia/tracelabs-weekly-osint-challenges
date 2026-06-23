# Engagements

Eksempel-engagements der demonstrerer hvordan toolboxen
(`.claude/skills/` + `.claude/recipes/`) anvendes i sammenhængende
kommercielle forløb.

Filerne her er **skabeloner og mock-tilbud**, ikke historik over
reelle gennemførte kunder. Brug dem som udgangspunkt ved scoping af
nye opgaver eller tilbudsskrivning: kopiér, udskift kunde/scope/
tidsplan, og brug tool-coverage-matrixen til at vise hvor stor en
del af paletten et engagement aktiverer.

## Skabeloner

| Fil | Type | Toolbox-bredde |
|---|---|---|
| `nordlys-maritime.md` | Full-stack engagement (OSINT + red + blue) — fiktiv shipping-kunde med CEO-fraud, impersonation og insider-mistanke som anledning | 14/15 OSINT-skills, 4/4 red, 4/4 blue, 18/26 recipes |
| `danmarks-nationalbank-fake-news.md` | Mock-tilbud på reelt offentligt udbud (DNB, deadline 8. juni 2026) — managed brand-protection-service "BrandVagten" med to scope-tiers (institution vs. + ledelse), tre-delt prisstruktur og take-down-workflow | 12/15 OSINT, 2/4 red (defensivt), 1/4 blue, 14/26 recipes |
| `danmarks-nationalbank-baseline-scan.md` | **Reelt pilot-scan** udført med vores toolbox mod DNB's offentlige overflade (15 min, passiv OSINT). Demonstrerer typen af fund BrandVagten leverer dag 14. Fandt 18+ defensiv-portfolio + 3 3rd-party-ejede gaps + åbne typo-permutationer. Bruger 3 nye recipes (urlscan, ct-search, urlhaus) | 6 skills, 7 recipes inkl. 3 nye |
| `danmarks-nationalbank-optionB-scan.md` | **Option B-pilot** — eksekutiv-coverage for DNB-direktion (Christian Kettel Thomsen, Signe Krogstrup, Ulrik Nødgaard). Fandt 2 Bluesky handle-grabs (heraf 1 med mistænkelig timing), identificerede X-verifikations-blindspot, dokumenterede pretexting-risiko fra DNB's egne offentlige biografier, og leverede 7 prioriterede anbefalinger (P0 = claim 5+ tilgængelige Bluesky-aliasser **i dag** for 0 DKK) | 6 skills, 4 recipes |
| `danmarks-nationalbank-socmint-scan.md` | **SOCMINT-pilot** — dedikeret social-media-intelligence på tværs af Bluesky, Reddit, Mastodon, Telegram, Meta Ad Library. **Kritisk fund: `@dnbofficial` på Telegram er taget af suspect aktør** ("Kerja Cerdas17"). Identificerede 9 DNB-medarbejder-profiler på Bluesky (strukturel attack surface). 7 ledige Telegram-handles + 3 ledige Mastodon-handles = defensiv portfolio-gap. Bygger 5 nye `socmint-*.sh` recipes | 5 nye recipes |

## Etisk note

Selv om kunder her er fiktive eller udbud er endnu ikke vundet,
gælder samme regler som ved reelle engagements:

- Ingen PII i deliverables uden samtykke + DPIA
- SOW + skriftlig autorisation før ét eneste query mod et reelt mål
- Stop-kriterier fra `.claude/agents/ethics-escalation.md` er
  ufravigelige
- Recipes med autorisations-krav (`redteam-*`) bruges aldrig
  uden in-scope-bekræftelse
- Tilbuds-skabeloner refererer kun til offentligt tilgængelige
  informationer om potentielle kunder (CVR, hjemmeside, offentlige
  udbud) — ingen privilege-info, ingen kontakt-prospecting bag login

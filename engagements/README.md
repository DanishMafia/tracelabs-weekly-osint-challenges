# Engagements

Eksempel-engagements der demonstrerer hvordan toolboxen
(`.claude/skills/` + `.claude/recipes/`) anvendes i sammenhængende
kommercielle forløb.

Filerne her er **skabeloner**, ikke historik over reelle kunder.
Brug dem som udgangspunkt ved scoping af nye opgaver: kopiér,
udskift kunde/scope/tidsplan, og brug tool-coverage-matrixen til
at vise hvor stor en del af paletten et engagement aktiverer.

## Skabeloner

| Fil | Type | Toolbox-bredde |
|---|---|---|
| `nordlys-maritime.md` | Full-stack engagement (OSINT + red + blue) — fiktiv shipping-kunde med CEO-fraud, impersonation og insider-mistanke som anledning | 14/15 OSINT-skills, 4/4 red, 4/4 blue, 18/26 recipes |

## Etisk note

Selv om kunder her er fiktive, gælder samme regler som ved reelle
engagements:

- Ingen PII i deliverables uden samtykke + DPIA
- SOW + skriftlig autorisation før ét eneste query
- Stop-kriterier fra `.claude/agents/ethics-escalation.md` er
  ufravigelige
- Recipes med autorisations-krav (`redteam-*`) bruges aldrig
  uden in-scope-bekræftelse

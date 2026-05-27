# Ethics escalation matrix

Hvornår agenten **skal** stoppe og kalde `AskUserQuestion` i stedet
for at fortsætte autonomt.

## Hard stops (altid escalér)

Disse er ufravigelige — ingen overruling fra brugeren uden eksplicit
"jeg er klar over risikoen og vil fortsætte alligevel":

| Scenarie | Handling |
|---|---|
| Artefakt identificerer **reel privatperson** (ikke kendt offentligt) | Stop, beskriv hvad du fandt, spørg om at fortsætte |
| Lokation peger på **privat hjem / adresse på reel privatperson** | Stop |
| Mindreårig synlig i billedet | Stop |
| Spor leder til **darkweb-marked / illegal handel** | Stop |
| Mistanke om **CSAM** eller voldsmateriale | Stop øjeblikkeligt, ingen yderligere request mod kilden |
| **Doxing-vinkel** (sammenholde flere PII-bits til realperson) | Stop |
| Spor kræver **brud på platforms ToS** (scraping bag login, falske konti) | Stop |
| **Aktiv scanning** af mål (port scan, nmap, brute force) | Stop |
| **Reverse engineering af proprietær software** med tvivlsom legal status | Stop |

## Soft stops (vurdér, escalér ved tvivl)

| Scenarie | Handling |
|---|---|
| Kendt offentlig person, men opgaven afslører ikke-offentlig info (hjemmeadresse, familiemedlemmer) | Stop |
| Image fra social media-konto der ser semi-privat ud | Vurdér; escalér ved tvivl |
| Reverse search returnerer kun resultater fra én persons sociale konto | Escalér — kunne være den person der har taget billedet |
| Vejr/lokations-præcision på meter-niveau for privat sted | Redact til generel område |
| Multiple data-bits der kombineret kunne identificere én person | Stop, lad brugeren beslutte aggregering |

## Bør IKKE eskalere (proceed normalt)

| Scenarie | Begrundelse |
|---|---|
| Identifikation af landmarks (Times Square, Mt. Fuji m.fl.) | Offentlige steder |
| Identifikation af kendte virksomheder / hovedkvarter | Offentlig info |
| Sporing af celebrity-fly via offentlige trackers (`@elonjet`) | Trackeren er allerede offentlig OSINT |
| Reverse-geocoding af koordinater til adresse | Mekanisk transformation |
| Decoding af offentligt encoded data (base64, w3w) | Mekanisk |
| Læsning af offentlige Wikipedia/OSM-poster | Åbne data |

## Escalation-format

Når der eskaleres, brug `AskUserQuestion` med:

```
question: "Jeg fandt [konkret artefakt der trigger stop].
            Skal jeg fortsætte? Bemærk [specifik risiko]."
options:
  - "Ja, fortsæt" + description med konkret rationale
  - "Nej, abandonér opgaven" + description
  - "Fortsæt men redact [specifik del]"
```

Dokumentér i write-up'et hvorfor en escalation skete, og hvad
brugeren valgte. Det er del af learning-trail'en.

## Output ved escalation

Hvis brugeren siger "nej, abandonér":

- Skriv en partial write-up med `status: abandoned`
- Inkluder en sektion "**Stoppet pga. etisk afgrænsning**" der
  forklarer hvilken regel der blev udløst, uden at re-eksponere
  den følsomme info
- Markér i frontmatter: `escalations: ["pii-detected", ...]`

## Eksempler fra praksis (hypotetiske)

| Opgave | Trigger | Handling |
|---|---|---|
| "Identificér personen på dette billede fra Instagram" | Reel person, semi-privat | Stop, escalér |
| "Find Elon Musks landing 19/9" | Kendt celebrity, offentlig tracker | Proceed |
| "Hvad er adressen til denne villa fra Zillow?" | Privatpersons hjem | Stop, escalér |
| "Geolocate dette landskab" | Naturmotiv uden mennesker | Proceed |
| "Decode denne Discord-besked" | Discord = login-baseret | Stop, escalér |
| "Decode denne base64 fra Challenge.md" | Challenge.md er åbent | Proceed |

## Test cases for agenten

Når agenten regression-testes, inkludér:

1. **week01-10 (alle nuværende)**: ingen escalation forventet
2. **Hypotetisk PII-week** (kommer evt.): test escalation-flow
3. **Tom challenge.md**: test om agenten kalder AskUserQuestion for
   manglende input
4. **Modstridende kilder**: test om confidence falder til low →
   escalation

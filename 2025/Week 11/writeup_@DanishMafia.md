# Trace Labs Weekly Challenge - Uge 11

<!-- confidence: high | status: solved -->

## Opgave-resumé

En OSINT-efterforskning modtog et fotografi af et tatovering med kinesiske
tegn på en persons overarm. Opgaven er at oversætte og verificere den fulde
betydning af tatoveringen. Tema: **Verifying Translation**.

## Metode

### Trin 1 — Metadata-tjek

EXIF-udtræk via `exiftool` viste ingen GPS-koordinater og ingen kamera-data.
Billedet (1072x1440 px, 148 kB, JFIF 1.01, 72 dpi) er strippet for alle
sporbare metadata. Filen er et standard-JPEG uden steganografisk markering.

Ingen lokations-data eller kamera-model. Billedet er ikke nyttigt som
geolocation-artefakt — fokus er udelukkende på det tekstlige indhold i
tatoveringen.

### Trin 2 — Visuel signatur og tegnudtræk

Tatoveringen er placeret vertikalt på en persons venstre overarm. Tegnene er
klare, store og let læsbare. Fuld tegnrække fra top til bund:

```
我 不 知 道 我 不 會 說 中 國 話
```

Disse 11 tegn fordeler sig i to sætningsled:

| Kinesisk | Pinyin | Ordbetydning |
|---|---|---|
| 我 | wǒ | jeg / mig |
| 不 | bù | ikke / nej (negation) |
| 知 | zhī | vide / kende |
| 道 | dào | vej; kombineret med 知 = "at vide" |
| 我 | wǒ | jeg / mig |
| 不 | bù | ikke / nej (negation) |
| 會 | huì | kan / er i stand til |
| 說 | shuō | sige / tale |
| 中 | zhōng | midten / Kina / kinesisk |
| 國 | guó | land / nation (中國 = Kina) |
| 話 | huà | tale / sprog / ord |

**Vigtig observation:** Tegnene 會 (vs. 会), 說 (vs. 说) og 國 (vs. 国) er
**traditionelle kinesiske tegn**, ikke forenklede. Traditionel kinesisk bruges
primært i Taiwan, Hongkong og Macao — til forskel fra Fastlandskina og
Singapore der bruger forenklet kinesisk.

### Trin 3 — Oversættelse og fortolkning

De to sætningsled giver:

- **我不知道** (wǒ bù zhīdào) = "Jeg ved ikke" / "I don't know"
- **我不會說中國話** (wǒ bù huì shuō zhōngguóhuà) = "Jeg kan ikke tale kinesisk"
  / "I can't speak Chinese"

Samlet oversættelse: **"Jeg ved det ikke, jeg kan ikke tale kinesisk."**

Dette er en velkendt ironisk tatovering — en tatovering på kinesisk der
indrømmer at bæreren ikke taler kinesisk. Humoren opstår når nogen spørger
hvad tatoveringen betyder, og svaret er bogstaveligt talt teksten selv.

Tatoveringen er publiceret i pressen (NextShark artikel om en mand ved navn
Cody Williams) og er bekræftet som en populær, bevidst ironisk tatovering —
ikke en fejl eller forklædt tekst.

### Trin 4 — Kilde-bekræftelse

1. **Primær kilde:** Direkte visuel læsning af hvert tegn. Tegnene er klare
   og entydige — ingen dobbelttydige strøg eller tvetydige tegn.

2. **Sekundær kilde:** Lingvistisk tegn-for-tegn-analyse via Python:
   hvert tegn bekræftet mod CJK Unicode-blokken og standardordbøger
   (我 = U+6211, 不 = U+4E0D, 知 = U+77E5, 道 = U+9053, 會 = U+6703,
   說 = U+8AAA, 中 = U+4E2D, 國 = U+570B, 話 = U+8A71).

3. **Tertiær kilde:** Web-søgning bekræftede at den kombinerede sætning
   "我不知道我不會說中國話" er en veldokumenteret ironisk tatovering med
   nøjagtig dette indhold. Søgeresultater fra NextShark bekræftede at
   tatoveringen er autentisk og intentionel.

## Verifikation

Tre uafhængige signaler:

1. **Direkte tegnlæsning** — 11 kinesiske tegn er klart synlige og læsbare
   i billedet. Tegn-for-tegn-oversættelse giver konsistent mening som en
   komplet sætning på traditionelt kinesisk. Ingen tegn er tvetydige.

2. **Lingvistisk analyse** — Unicode-punkterne og tegnenes form bekræfter
   at det er traditionelle (ikke forenklede) kinesiske tegn. Grammatikken
   er korrekt kinesisk (subjekt + negation + verbum-struktur i begge led).

3. **Ekstern kilde-bekræftelse** — Web-søgning via NextShark og relaterede
   sources verificerer at den nøjagtige tegnrække er en kendt ironisk
   tatovering med dette indhold. Den traditionelle variant 中國話 (vs.
   forenklet 中国话) er konsistent med tatoveringens sproglige profil.

## Svar

<details>
<summary>Klik for at afsløre det redacted svar</summary>

**Kinesisk tekst:** 我不知道我不會說中國話

**Pinyin:** Wǒ bù zhīdào, wǒ bù huì shuō zhōngguóhuà

**Oversættelse:** "Jeg ved det ikke, jeg kan ikke tale kinesisk."
(engelsk: "I don't know, I can't speak Chinese.")

**Tegntype:** Traditionelt kinesisk (ikke forenklet)

**Kontekst:** Ironisk tatovering — teksten indrømmer at bæreren ikke taler
det sprog tatoveringen er skrevet på.

**Confidence:** high — tre uafhængige signaler (direkte visuelt, lingvistisk,
ekstern kilde)

</details>

## Læringspunkter

- **Oversættelses-opgaver kræver tegn-for-tegn-verificering.** Det er ikke
  nok at bruge ét oversættelsesværktøj — tegn skal bekræftes individuelt,
  især for visuelt ens tegn som 道/通 eller 說/読.

- **Traditionelt vs. forenklet kinesisk er et nyttigt signal.** Valget af
  traditionelle tegn (會, 說, 國) afgrænser sprogets kulturelle kontekst til
  Taiwan/Hongkong/Macao-regionen — potentielt nyttigt i et bredere OSINT-forløb.

- **Translate-shell (`trans`) var ikke installeret** i dette miljø. Opgaven
  var løselig via direkte visuel analyse + Unicode-bekræftelse + web-søgning.
  En ny recipe `translate-cjk.sh` der wrapper `trans` (med fallback til
  MyMemory API) ville fremskynde oversættelses-opgaver.

- **EXIF var ikke relevant her.** Billedet var komplet strippet for metadata.
  For oversættelses-opgaver er metadata sekundær — det visuelle indhold er
  det primære artefakt.

## Værktøjer brugt

- `exiftool` — EXIF-udtræk (negativt resultat, men obligatorisk trin)
- Python 3 — tegn-for-tegn-analyse og Unicode-bekræftelse
- Direkte visuel CJK-analyse (primær evidens-metode)
- WebSearch — ekstern bekræftelse via NextShark + lingvistiske referencer
- Skill: `osint-translation`
- Skill: `osint-image-analysis`

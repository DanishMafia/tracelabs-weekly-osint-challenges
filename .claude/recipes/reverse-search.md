# Reverse Image Search — opskrift

Manuel procedure. Kan ikke skriptes pålideligt (kræver browser-sessioner,
captchas, og forskellige UIs).

## Forudsætninger

- Billedet downloadet lokalt (brug `fetch-challenge.sh`)
- Browser med adgang til Google Lens, Yandex og TinEye

## Procedure

### 1. Forbered crops (vigtigt!)

Et fuldt billede kan give støjende resultater. Lav crops af de mest
karakteristiske elementer:

```bash
# Crop med ImageMagick: udskær center 60% (eksempel)
convert input.jpg -gravity center -crop 60%x60%+0+0 +repage center.jpg

# Crop specifik region (x,y,w,h)
convert input.jpg -crop 800x600+200+100 +repage region.jpg
```

Sigt efter: skilte, logoer, bygninger, distinkte landmarks, ansigter
(kun for challenge-personaer).

### 2. Kør i flere motorer

Ranger fra højest til lavest hit-rate i praksis:

| Motor | URL | Styrker |
|---|---|---|
| Google Lens | https://lens.google.com | Landmarks, tekst-OCR, produkter |
| Yandex Images | https://yandex.com/images | Ansigter, europæiske billeder, eksakte kopier |
| TinEye | https://tineye.com | Eksakte og næsten-eksakte kopier, ældste forekomst |
| Bing Visual Search | https://www.bing.com/visualsearch | Backup når Google og Yandex fejler |

### 3. Analyser resultater systematisk

For hver hit:
1. **Klik kilden** — er det stock, Wikipedia, Instagram, blog?
2. **Tjek alder** — TinEye's "oldest" filter afslører første kendte
   upload (kan indikere kilde-fotograf)
3. **Læs filnavnet** på den oprindelige fil — kan rumme stednavn,
   eventnavn, dato
4. **Cross-check tre uafhængige hits** før konklusion

### 4. Hvis ingen hits

- **Crop og prøv igen** med en mindre/anden region
- **Søg tekstuelt** ud fra visuelle ledetråde ("alpine lake church
  island autumn" osv.)
- **Skift til geologisk/arkitektonisk OSINT** — beskriv elementerne
  og søg på dem
- **Tjek metadata-feltet** for OEM-vandmærker fra stock-platforme

## Røde flag

- **For mange perfekte matches** = sandsynligvis stock-billede
  → tjek Getty/Shutterstock/Unsplash for original-URL og credit
- **Kun match på sociale platforme** = nyligt eller personligt billede
  → vær ekstra forsigtig med PII
- **Hits peger på flere lokationer** = motiv er for generisk
  → triangulér med andre signaler i stedet

## Konsekvenser for write-up

Hvis et hit afslører fotografen eller posters identitet: dette er
PII og må **ikke** med i write-up'en. Henvis kun til ophavsret-side
hvis billedet er stock.

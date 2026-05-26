---
name: osint-translation
description: Oversættelse af fremmedsproget indhold i OSINT-undersøgelser. Brug ved spørgsmål om "oversæt", "translate", "DeepL", "translate-shell", eller når et artefakt er på et sprog brugeren ikke forstår (skilte, posts, dokumenter).
---

# Translation (OSINT)

Brug denne skill når et artefakt er på et fremmed sprog — fx skilte i et
billede, posts på sociale medier, eller dokumenter.

## Workflow

1. **Identificér sproget først.** Forkert sprog-detektion → forkert
   oversættelse. Google Translate's auto-detect er ofte god nok.
2. **Brug flere motorer.** DeepL er stærk på europæiske sprog, Google på
   asiatiske; sammenlign for nuancer.
3. **Bevar originalen** i write-up sammen med oversættelsen — så andre
   kan verificere.
4. **Translitterér ikke-latinske skrifter** (kyrillisk, arabisk, CJK) før
   du citerer i prosa.

## Værktøjer (fra Trace Labs / awesome-osint, MPL-2.0)

*Tools to help translate and understand foreign-language content.*

- [Translate Shell](https://github.com/soimort/translate-shell) – Command-line translator powered by Google, Bing, Yandex, and more.
- [DeepL](https://www.deepl.com/) – High-quality translation service with strong support for European and Asian languages.

## Etisk note

- Oversættelse af følsomme private beskeder hører ikke hjemme i en
  challenge-write-up.
- Maskinoversættelse er ikke autoritativ — markér det tydeligt.

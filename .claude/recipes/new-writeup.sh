#!/bin/bash
# Scaffolder en ny writeup_@<handle>.md i den korrekte ugemappe.
#
# Brug:
#   ./new-writeup.sh "Week 15" DanishMafia
#   ./new-writeup.sh week01 DanishMafia
#
# Filen oprettes med dansk skabelon. Eksisterer den allerede, abort.

set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <week-folder> <handle>" >&2
  echo "Example: $0 \"Week 15\" DanishMafia" >&2
  exit 1
fi

WEEK="$1"
HANDLE="$2"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
TARGET="$REPO_ROOT/2025/$WEEK/writeup_@${HANDLE}.md"

if [ ! -d "$REPO_ROOT/2025/$WEEK" ]; then
  echo "Error: 2025/$WEEK findes ikke" >&2
  exit 1
fi

if [ -f "$TARGET" ]; then
  echo "Error: $TARGET findes allerede — vil ikke overskrive" >&2
  exit 1
fi

# Udled uge-nummer fra mappenavn (Week 15 → 15, week01 → 01)
NUM="$(echo "$WEEK" | tr -d -c '0-9')"
[ -z "$NUM" ] && NUM="??"

cat > "$TARGET" << EOF
# Trace Labs Weekly Challenge - Uge ${NUM}

## Opgave-resumé

(Kort omformulering — kopiér ikke rå Discord/challenge-tekst.)

## Metode

### Trin 1 — Metadata-tjek

(Resultat af \`exiftool\` / \`inspect-image.sh\` — strippet EXIF? filnavns-hint?)

### Trin 2 — Visuel signatur

(Hvilke artefakter står frem? Skilte, vegetation, arkitektur, geologi, sprog?)

### Trin 3 — Hypoteser og søgning

(Hvilke spor blev forfulgt? Reverse image search? Specifikke søgetermer?)

### Trin 4 — Kilde-bekræftelse

(Hvilke kilder verificerede hypotesen?)

## Verifikation

To uafhængige signaler:

1. **(Signal 1)** — beskrivelse + kilde
2. **(Signal 2)** — beskrivelse + kilde

## Svar

<details>
<summary>Klik for at afsløre det redacted svar</summary>

**Lokation:** [skjult]

**Koordinater:** [hvis relevant]

**Format som opgaven beder om:** [skjult]

**Verifikation:** [kort begrundelse]

</details>

## Læringspunkter

- (Hvad virkede?)
- (Hvad virkede ikke?)
- (Hvilke værktøjer var mest effektive?)

## Værktøjer brugt

- \`exiftool\` / \`inspect-image.sh\`
- (Reverse image search-motor)
- (Krydsreferencer)
- Skills: (relevant osint-* skill(s))
EOF

echo "Oprettet: $TARGET"
echo "Næste skridt:"
echo "  1. Udfyld sektionerne"
echo "  2. git add \"$TARGET\""
echo "  3. git commit + push på writeup/week-${NUM} branch"

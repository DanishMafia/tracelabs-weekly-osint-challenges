#!/bin/bash
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

REPO_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
YEAR_DIR="$REPO_ROOT/2025"

echo "=== Trace Labs Weekly OSINT Challenges ==="
echo ""
echo "Repo-rod: $REPO_ROOT"
echo ""

if [ -d "$YEAR_DIR" ]; then
  echo "Tilgængelige uger i 2025/ (sorteret):"
  ls "$YEAR_DIR" \
    | grep -Ei '^(week ?[0-9]+)$' \
    | awk '{
        n = $0
        sub(/^[Ww]eek ?/, "", n)
        printf "%02d\t%s\n", n+0, $0
      }' \
    | sort -n \
    | cut -f2- \
    | sed 's/^/  - /'
  echo ""

  LATEST=$(ls "$YEAR_DIR" \
    | grep -Ei '^(week ?[0-9]+)$' \
    | awk '{
        n = $0
        sub(/^[Ww]eek ?/, "", n)
        printf "%d\t%s\n", n+0, $0
      }' \
    | sort -n \
    | tail -1 \
    | cut -f2-)
  echo "Seneste uge: $LATEST"
  if [ -f "$YEAR_DIR/$LATEST/Challenge.md" ]; then
    echo "  Challenge:   2025/$LATEST/Challenge.md"
  elif [ -f "$YEAR_DIR/$LATEST/challenge.md" ]; then
    echo "  Challenge:   2025/$LATEST/challenge.md"
  fi
  if [ -f "$YEAR_DIR/$LATEST/Official Walkthrough.md" ]; then
    echo "  Walkthrough: 2025/$LATEST/Official Walkthrough.md"
  fi
fi

echo ""
echo "Write-up skabelon: Contributing.md (sektion 'Write-Up Template')"
echo "Filnavn-konvention: writeup_@dithandle.md i den relevante uge-mappe"
echo ""
echo "Regler (kort):"
echo "  - Skriv write-ups på dansk (filnavne/struktur på engelsk)"
echo "  - Redacter altid svaret bag <details>-tags"
echo "  - Ingen rå Discord-tekst, personlige data eller ikke-offentlige URLs"
echo "  - Kun etiske, åbne kilder"
echo ""
echo "Se CLAUDE.md for fuld metodologi og arbejdsgang."

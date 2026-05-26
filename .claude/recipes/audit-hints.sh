#!/bin/bash
# Audit-værktøj: viser hvad challenge-forfatteren utilsigtet røbede via
# markdown alt-text og URL-filnavne.
#
# FORMÅL: efter et write-up er skrevet, brug dette til at verificere at
# du IKKE har "snydt" ved at læse hints. Hvis dit svar matcher noget i
# audit-output, men din metode-sektion ikke nævner visuel/EXIF/ekstern
# verifikation, så har du sandsynligvis snydt.
#
# Må IKKE bruges som inputkilde til write-up'et selv.
#
# Brug:
#   ./audit-hints.sh /tmp/week15

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <download-dir>" >&2
  exit 1
fi

DIR="$1"
HINTS="$DIR/.hints.tsv"

if [ ! -f "$HINTS" ]; then
  echo "Ingen .hints.tsv i $DIR (kør først fetch-challenge.sh)" >&2
  exit 1
fi

echo "===================================================================="
echo "AUDIT: hvad challenge-forfatteren utilsigtet røbede"
echo "(POST-HOC verifikation — må ikke bruges i write-up'et)"
echo "===================================================================="
echo

while IFS=$'\t' read -r FILE URL HINT; do
  echo "Fil: $FILE"
  echo "  URL:  $URL"
  echo "  Alt:  ${HINT:-(ingen)}"
  if [ -n "${HINT:-}" ]; then
    # Detektér potentielle stednavne / objekter
    TOKENS="$(echo "$HINT" | tr '_/.-' '    ' | tr -cd 'a-zA-Z \n' | tr -s ' \n' ' ')"
    echo "  Tokens: $TOKENS"
    if echo "$TOKENS" | grep -Eiq '\b(in|at|near|of)\s+[A-Za-z]'; then
      echo "  ⚠ Hint ser ud til at indeholde lokationsbeskrivelse"
    fi
  fi
  echo
done < "$HINTS"

echo "Hvis dit write-up's konklusion matcher ovenstående hints,"
echo "skal du kunne pege på uafhængig visuel/EXIF/ekstern evidens"
echo "i metode-sektionen. Ellers: redo write-up'et uden hints."

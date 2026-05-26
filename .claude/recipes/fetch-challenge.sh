#!/bin/bash
# Henter alle billed-URLs fra en Challenge.md og downloader dem.
#
# Brug:
#   ./fetch-challenge.sh 2025/Week\ 15/Challenge.md
#   ./fetch-challenge.sh 2025/week01/challenge.md
#
# Output: /tmp/<sanitized-week>/<n>_<basename>.<ext>

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <path-to-Challenge.md>" >&2
  exit 1
fi

CHALLENGE_MD="$1"
if [ ! -f "$CHALLENGE_MD" ]; then
  echo "Error: $CHALLENGE_MD findes ikke" >&2
  exit 1
fi

# Udled ugemappe-navnet → sanitized dir name (Week 15 → week15)
WEEK_DIR="$(basename "$(dirname "$CHALLENGE_MD")")"
SAFE_WEEK="$(echo "$WEEK_DIR" | tr 'A-Z' 'a-z' | tr -d ' ')"
OUT_DIR="/tmp/$SAFE_WEEK"
mkdir -p "$OUT_DIR"

# Udtræk URL + alt/filename-hint som "URL\tHINT" linjer.
# Markdown: ![alt-text](url)  → alt-text er hint
# HTML:     <img src="url" ... alt="text"> → alt er hint
URL_HINT_PAIRS="$(
  perl -ne '
    while (/!\[([^\]]*)\]\(([^)]+)\)/g)        { print "$2\t$1\n"; }
    while (/<img[^>]*\bsrc="([^"]+)"[^>]*\balt="([^"]*)"/g) { print "$1\t$2\n"; }
    while (/<img[^>]*\bsrc="([^"]+)"/g)        { print "$1\t\n"; }
  ' "$CHALLENGE_MD" \
    | awk -F'\t' '$1 ~ /^https?:\/\// && ($1 ~ /\.(jpg|jpeg|png|gif|webp)([?#]|$)/ || $1 ~ /user-attachments\/assets\//)' \
    | sort -u
)"

if [ -z "$URL_HINT_PAIRS" ]; then
  echo "Ingen billed-URLs fundet i $CHALLENGE_MD" >&2
  exit 0
fi

echo "Output-mappe: $OUT_DIR"
# NO-CHEAT: vi gemmer URL + alt-text i en SKJULT fil som audit-trail,
# men printer dem aldrig til stdout. Det forhindrer at en agent eller
# læser "ser" hintet og bruger det som primær OSINT-evidens.
: > "$OUT_DIR/.hints.tsv"
chmod 600 "$OUT_DIR/.hints.tsv"
N=0
while IFS=$'\t' read -r URL HINT; do
  [ -z "$URL" ] && continue
  N=$((N+1))
  # Udled filnavn fra URL (sidste segment, evt. uden query)
  BASENAME="$(basename "${URL%%\?*}")"
  # GitHub user-attachments har UUIDs uden ext — gæt .jpg
  case "$BASENAME" in
    *.jpg|*.jpeg|*.png|*.gif|*.webp) EXT="${BASENAME##*.}"; STEM="${BASENAME%.*}" ;;
    *) EXT="jpg"; STEM="$BASENAME" ;;
  esac
  # NO-CHEAT: navngiv lokalt med sekvens-nummer + opake hash, IKKE STEM
  # (STEM kan indeholde domæne-information fra URL'en).
  HASH="$(echo -n "$URL" | sha1sum | cut -c1-8)"
  OUT="$OUT_DIR/$(printf '%02d' "$N")_${HASH}.${EXT}"
  printf 'Henter [%d] → %s\n' "$N" "$OUT"
  curl -sL "$URL" -o "$OUT"
  if ! file "$OUT" | grep -qiE 'image|JPEG|PNG|GIF|WebP'; then
    echo "  ADVARSEL: $OUT ser ikke ud til at være et billede" >&2
  fi
  # Skriv til hidden audit-fil — aldrig til stdout
  printf '%s\t%s\t%s\n' "$OUT" "$URL" "$HINT" >> "$OUT_DIR/.hints.tsv"
done <<< "$URL_HINT_PAIRS"

echo
echo "Færdig. $N fil(er) i $OUT_DIR"
echo "(hints gemt i $OUT_DIR/.hints.tsv — vis kun via ./audit-hints.sh)"

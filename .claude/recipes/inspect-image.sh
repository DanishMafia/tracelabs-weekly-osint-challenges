#!/bin/bash
# Inspicer et billede: EXIF + filnavns-hint + dimensioner.
#
# Brug:
#   ./inspect-image.sh /tmp/week15/01_challenge.jpg
#
# Output: struktureret rapport til stdout.

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <image-path> [<image-path>...]" >&2
  exit 1
fi

for IMG in "$@"; do
  if [ ! -f "$IMG" ]; then
    echo "Error: $IMG findes ikke" >&2
    continue
  fi

  echo "============================================================"
  echo "Fil: $IMG"
  echo "============================================================"

  # Basale fil-info
  echo "[Fil-info]"
  file "$IMG"
  echo "  Størrelse: $(du -h "$IMG" | cut -f1)"
  echo

  # Filnavns-hint — fra url-map.txt skrevet af fetch-challenge.sh
  DIR="$(dirname "$IMG")"
  if [ -f "$DIR/url-map.txt" ]; then
    HINT=$(awk -F'\t' -v f="$IMG" '$1==f {print $3}' "$DIR/url-map.txt" || true)
    URL=$(awk -F'\t' -v f="$IMG" '$1==f {print $2}' "$DIR/url-map.txt" || true)
    if [ -n "$HINT" ] || [ -n "$URL" ]; then
      echo "[Markdown/URL hint]"
      [ -n "$URL" ]  && echo "  URL:  $URL"
      [ -n "$HINT" ] && echo "  Alt:  $HINT"
      # Detektér læsbare ord (kan røbe lokation/objekt)
      WORDS="$(printf '%s\n' "$HINT" "$URL" | tr '_/.-' '    ' | tr -cd 'a-zA-Z \n' | tr -s ' \n' ' ')"
      if [ -n "$WORDS" ] && echo "$WORDS" | grep -Eiq '[a-z]{4,}'; then
        echo "  Læsbare tokens: $WORDS"
        echo "  → Tjek om hint røber lokation/objekt før dyb analyse!"
      fi
      echo
    fi
  fi

  # EXIF — hele dump først, derefter highlight af kritiske felter
  if ! command -v exiftool >/dev/null 2>&1; then
    echo "  ADVARSEL: exiftool ikke installeret. Kør:" >&2
    echo "    sudo apt-get install -y libimage-exiftool-perl" >&2
    continue
  fi

  echo "[EXIF — kritiske felter]"
  CRIT=$(exiftool -s -GPSLatitude -GPSLongitude -GPSPosition \
                  -CreateDate -DateTimeOriginal -ModifyDate \
                  -Make -Model -Software -LensModel \
                  -Artist -Copyright -ImageDescription \
                  "$IMG" 2>/dev/null)
  if [ -n "$CRIT" ]; then
    echo "$CRIT" | sed 's/^/  /'
  else
    echo "  (ingen kritiske EXIF-felter fundet — sandsynligvis strippet)"
  fi
  echo

  # Hint hvis billedet sandsynligvis er fra en social/CDN platform
  echo "[Heuristik]"
  if exiftool -s -JFIFVersion "$IMG" 2>/dev/null | grep -q '1.01'; then
    echo "  JFIF 1.01 → typisk re-encoded af social/CDN platform (EXIF ofte væk)"
  fi
  if ! exiftool -s -Make "$IMG" 2>/dev/null | grep -q .; then
    echo "  Ingen kamera-Make → EXIF strippet eller stock-billede"
  fi
  echo

done

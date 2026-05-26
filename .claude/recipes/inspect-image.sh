#!/bin/bash
# Inspicer et billede: EXIF + dimensioner.
#
# Brug:
#   ./inspect-image.sh /tmp/week15/01_challenge.jpg
#
# Output: struktureret rapport til stdout.
#
# NO-CHEAT REGEL: dette script viser IKKE markdown-alt-text eller
# URL-filnavne. Den slags er accidentielt lækket metadata fra
# challenge-forfatteren, ikke gyldig OSINT-evidens. Et write-up må
# kun bygge på visuel analyse, EXIF og eksterne kilder. Brug
# ./audit-hints.sh hvis du har brug for at *kontrollere* hvad der
# blev lækket (post-hoc, ikke som primær evidens).

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

  # Markdown alt-text og URL-filnavne vises bevidst IKKE her —
  # de er "challenge-author leak", ikke OSINT-evidens. Se audit-hints.sh
  # hvis du bagefter vil verificere at write-up'en ikke utilsigtet
  # baserede sig på dem.

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

#!/bin/bash
# Scan alle EXIF/metadata-felter på et billede for encoded payloads
# (base64, hex, ROT13, URL-encoding). Auto-decode dem der ser tekstuelle ud.
#
# Bruges når EXIF GPS er strippet/fake, men der kan være skjulte hints i
# Note, UserComment, ImageDescription, Software, Artist osv.
#
# Brug:
#   ./decode-metadata.sh /tmp/week12/01_*.jpg

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <image-path> [<image-path>...]" >&2
  exit 1
fi

if ! command -v exiftool >/dev/null 2>&1; then
  echo "Error: exiftool kræves. apt-get install -y libimage-exiftool-perl" >&2
  exit 1
fi

# Felter der kan rumme bevidst placerede hints
SUSPECT_TAGS=(
  "UserComment" "Comment" "ImageDescription" "XPComment"
  "Artist" "Copyright" "Software" "Caption" "Title"
  "Subject" "Keywords" "Description" "Notes" "Note"
  "DocumentName" "PageName" "HostComputer" "Make" "Model"
  "OwnerName" "CameraOwnerName" "OwnerName"
  "XPSubject" "XPTitle" "XPAuthor" "XPKeywords"
  "Headline" "By-line" "ObjectName" "Instructions"
  "TransmissionReference" "EditStatus" "FixtureIdentifier"
  "OriginalTransmissionReference" "SpecialInstructions"
)

is_printable() {
  echo "$1" | grep -qE '^[[:print:][:space:]]+$' 2>/dev/null
}

try_decode() {
  local VALUE="$1"
  local TAG="$2"

  # base64
  if echo "$VALUE" | grep -qE '^[A-Za-z0-9+/]+=*$' \
     && [ ${#VALUE} -ge 8 ] && [ $((${#VALUE} % 4)) -eq 0 ]; then
    local D
    D=$(echo "$VALUE" | base64 -d 2>/dev/null || true)
    if [ -n "$D" ] && is_printable "$D"; then
      echo "    base64 → $D"
    fi
  fi

  # hex
  if echo "$VALUE" | grep -qE '^[0-9a-fA-F]+$' \
     && [ $((${#VALUE} % 2)) -eq 0 ] && [ ${#VALUE} -ge 6 ]; then
    local D
    D=$(echo "$VALUE" | xxd -r -p 2>/dev/null || true)
    if [ -n "$D" ] && is_printable "$D"; then
      echo "    hex    → $D"
    fi
  fi

  # ROT13
  if echo "$VALUE" | grep -qE '^[A-Za-z[:space:][:punct:]]+$' \
     && echo "$VALUE" | grep -qE '[A-Za-z]{4,}'; then
    local R
    R=$(echo "$VALUE" | tr 'A-Za-z' 'N-ZA-Mn-za-m')
    if echo " $R " | grep -qiE ' (the|and|for|with|from|that|this|http|www|location|key|go|head|find) '; then
      echo "    ROT13  → $R"
    fi
  fi

  # URL-encoding
  if echo "$VALUE" | grep -qE '%[0-9A-Fa-f]{2}'; then
    local D
    D=$(printf '%b' "${VALUE//%/\\x}" 2>/dev/null || true)
    if [ -n "$D" ] && [ "$D" != "$VALUE" ]; then
      echo "    URL    → $D"
    fi
  fi

  # Reversed string (sjælden, men nem at tjekke)
  if [ ${#VALUE} -ge 8 ] && [ ${#VALUE} -le 200 ]; then
    local REV
    REV=$(echo "$VALUE" | rev)
    if echo " $REV " | grep -qiE ' (the|http|www|location|head|find|bridge) '; then
      echo "    rev    → $REV"
    fi
  fi
}

for IMG in "$@"; do
  if [ ! -f "$IMG" ]; then
    echo "Error: $IMG findes ikke" >&2
    continue
  fi

  echo "============================================================"
  echo "Fil: $IMG"
  echo "============================================================"

  FOUND=0
  for TAG in "${SUSPECT_TAGS[@]}"; do
    VALUE=$(exiftool -s -s -s -"$TAG" "$IMG" 2>/dev/null || true)
    [ -z "$VALUE" ] && continue
    FOUND=$((FOUND + 1))
    echo "[$TAG]"
    echo "  $VALUE"
    try_decode "$VALUE" "$TAG"
    echo
  done

  if [ "$FOUND" -eq 0 ]; then
    echo "(Ingen suspekte metadata-felter fundet)"
  fi
  echo
done

echo "Bemærk: GPS-koordinater kan være bevidst forkerte (uge 12-mønster)."
echo "Tjek altid Note/Comment/UserComment for hints der modsiger GPS."

#!/bin/bash
# QR-kode / stregkode-dekoder. Bruger zbarimg (zbar-tools) som primær,
# med fallback til ImageMagick-pre-processing hvis QR-koden er
# rotationsforvrænget eller lavkontrast.
#
# Brug:
#   ./qr-decode.sh /tmp/week15/01_*.jpg
#   ./qr-decode.sh image1.png image2.jpg

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <image> [<image>...]" >&2
  exit 1
fi

if ! command -v zbarimg >/dev/null 2>&1; then
  echo "Error: zbarimg kræves. apt-get install -y zbar-tools" >&2
  exit 1
fi

decode_one() {
  local IMG="$1"
  local LABEL="$2"

  zbarimg -q --raw "$IMG" 2>/dev/null || true
}

for IMG in "$@"; do
  if [ ! -f "$IMG" ]; then
    echo "Error: $IMG findes ikke" >&2
    continue
  fi

  echo "============================================================"
  echo "Fil: $IMG"
  echo "============================================================"

  # 1. Direkte
  echo "[zbarimg — direkte]"
  RESULT=$(decode_one "$IMG" "direkte")
  if [ -n "$RESULT" ]; then
    echo "$RESULT" | sed 's/^/  /'
    echo
    continue
  fi
  echo "  (ingen kode fundet)"
  echo

  # 2. Pre-process: grayscale + contrast
  if command -v convert >/dev/null 2>&1; then
    TMP=$(mktemp --suffix=.png)
    echo "[zbarimg — gråtone + auto-level]"
    convert "$IMG" -colorspace Gray -auto-level "$TMP" 2>/dev/null
    RESULT=$(decode_one "$TMP" "preprocessed")
    if [ -n "$RESULT" ]; then
      echo "$RESULT" | sed 's/^/  /'
      rm -f "$TMP"
      echo
      continue
    fi
    echo "  (intet)"

    # 3. Tær på + binarize
    echo "[zbarimg — threshold 50%]"
    convert "$IMG" -colorspace Gray -threshold 50% "$TMP" 2>/dev/null
    RESULT=$(decode_one "$TMP" "threshold")
    if [ -n "$RESULT" ]; then
      echo "$RESULT" | sed 's/^/  /'
      rm -f "$TMP"
      echo
      continue
    fi
    echo "  (intet)"
    rm -f "$TMP"
  fi

  echo "[Konklusion]  Ingen QR/stregkode kunne dekodes."
  echo "Tips: crop til QR-området, prøv højere opløsning, eller test"
  echo "      online med https://zxing.org/w/decode (kun til offentlige billeder)."
  echo
done

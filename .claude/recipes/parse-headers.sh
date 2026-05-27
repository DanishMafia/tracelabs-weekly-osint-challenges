#!/bin/bash
# Parse HTTP-headers fra fil eller stdin. Identificér custom (non-standard)
# headers og auto-decode kendte encodings (base64, hex, ROT13, URL).
#
# Brug:
#   ./parse-headers.sh headers.txt
#   curl -sI https://example.com | ./parse-headers.sh
#   cat <<EOF | ./parse-headers.sh
#   HTTP/1.1 200 OK
#   X-Clue: U2FuZHMgTGlmZXN0eWxlIENvdW50ZXIgKEhvdGVsIExvYmJ5KQ==
#   EOF

set -euo pipefail

# Standard HTTP-headers vi springer over (ikke OSINT-interessante)
STANDARD_HEADERS=(
  "host" "user-agent" "accept" "accept-encoding" "accept-language"
  "connection" "content-type" "content-length" "content-encoding"
  "cache-control" "date" "etag" "expires" "last-modified" "server"
  "vary" "x-powered-by" "x-frame-options" "x-content-type-options"
  "x-xss-protection" "strict-transport-security" "set-cookie"
  "location" "transfer-encoding" "pragma" "age" "via" "alt-svc"
  "p3p" "referrer-policy" "permissions-policy" "content-security-policy"
  "access-control-allow-origin" "access-control-allow-methods"
  "access-control-allow-headers" "access-control-allow-credentials"
  "access-control-expose-headers" "access-control-max-age"
  "cf-ray" "cf-cache-status" "report-to" "nel" "expect-ct"
)

# Læs input: fil-argument eller stdin
if [ $# -ge 1 ] && [ -f "$1" ]; then
  INPUT="$(cat "$1")"
else
  INPUT="$(cat)"
fi

if [ -z "$INPUT" ]; then
  echo "Usage: $0 <headers-file>     # or pipe headers via stdin" >&2
  exit 1
fi

# Parse linje-for-linje. Match "Name: Value" mønster.
echo "=== HTTP Headers Parse ==="
echo

CUSTOM_FOUND=0
while IFS= read -r LINE; do
  # Spring tomme linjer og statuslinjer (HTTP/1.1 …) over
  [[ -z "$LINE" || "$LINE" =~ ^HTTP/ ]] && continue

  # Match Name: Value
  if [[ "$LINE" =~ ^([A-Za-z][A-Za-z0-9_-]*):\ *(.+)$ ]]; then
    NAME="${BASH_REMATCH[1]}"
    VALUE="${BASH_REMATCH[2]}"
    NAME_LOWER="$(echo "$NAME" | tr '[:upper:]' '[:lower:]')"

    # Spring standard-headers over
    SKIP=0
    for STD in "${STANDARD_HEADERS[@]}"; do
      if [ "$NAME_LOWER" = "$STD" ]; then SKIP=1; break; fi
    done
    [ "$SKIP" -eq 1 ] && continue

    CUSTOM_FOUND=$((CUSTOM_FOUND + 1))
    echo "[Custom header] $NAME"
    echo "  Raw:    $VALUE"

    # Forsøg base64-decode (kun hvis det ligner base64)
    if echo "$VALUE" | grep -qE '^[A-Za-z0-9+/]+=*$' && [ ${#VALUE} -ge 8 ] && [ $((${#VALUE} % 4)) -eq 0 ]; then
      DECODED=$(echo "$VALUE" | base64 -d 2>/dev/null || true)
      if [ -n "$DECODED" ] && echo "$DECODED" | grep -qE '^[[:print:][:space:]]+$'; then
        echo "  base64: $DECODED"
      fi
    fi

    # Forsøg hex-decode (kun hvis det er hex og parlig længde)
    if echo "$VALUE" | grep -qE '^[0-9a-fA-F]+$' && [ $((${#VALUE} % 2)) -eq 0 ] && [ ${#VALUE} -ge 6 ]; then
      DECODED=$(echo "$VALUE" | xxd -r -p 2>/dev/null || true)
      if [ -n "$DECODED" ] && echo "$DECODED" | grep -qE '^[[:print:][:space:]]+$'; then
        echo "  hex:    $DECODED"
      fi
    fi

    # ROT13 (kun hvis værdien indeholder bogstaver der ser ikke-engelsk ud)
    if echo "$VALUE" | grep -qE '^[A-Za-z[:space:][:punct:]]+$' && echo "$VALUE" | grep -qE '[A-Za-z]{4,}'; then
      ROT=$(echo "$VALUE" | tr 'A-Za-z' 'N-ZA-Mn-za-m')
      # Vis kun hvis ROT13 producerer ord der ligner engelsk (vague heuristik:
      # mindst ét rigtigt engelsk fillerord)
      if echo " $ROT " | grep -qiE ' (the|and|for|with|from|that|this|http|www|location|key) '; then
        echo "  ROT13:  $ROT"
      fi
    fi

    # URL-decode (kun hvis værdien indeholder %XX-sekvenser)
    if echo "$VALUE" | grep -qE '%[0-9A-Fa-f]{2}'; then
      DECODED=$(printf '%b' "${VALUE//%/\\x}" 2>/dev/null || true)
      if [ -n "$DECODED" ] && [ "$DECODED" != "$VALUE" ]; then
        echo "  URL:    $DECODED"
      fi
    fi

    echo
  fi
done <<< "$INPUT"

if [ "$CUSTOM_FOUND" -eq 0 ]; then
  echo "(Ingen custom headers fundet — kun standard HTTP-headers)"
else
  echo "$CUSTOM_FOUND custom header(s) fundet."
  echo
  echo "Bemærk: custom headers med encoded værdier er sjældent tilfældige."
  echo "De er ofte bevidst placerede OSINT-spor. Følg semantisk hint i decoded text."
fi

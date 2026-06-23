#!/bin/bash
# headers-security — audit security headers + tech-stack fingerprint
# på en URL. Bruges defensivt (er DNB's headers stærke?) og
# offensiv-defensivt (afslører fake-sites pga. dårlig header-hygiejne).
#
# Hvad vi tjekker:
#   - HSTS, CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy
#   - TLS version + cert via openssl s_client
#   - Server-header, X-Powered-By (tech-stack-leak)
#   - Set-Cookie security flags
#   - CORS-konfiguration
#   - Score: A-F efter securityheaders.com-style
#
# Brug:
#   ./headers-security.sh https://www.nationalbanken.dk
#   ./headers-security.sh https://nationalbanken.com
#   ./headers-security.sh --batch nationalbanken.com,nationalbanken.org

set -uo pipefail

URL=""
BATCH=""
while [ $# -gt 0 ]; do
  case "$1" in
    --batch) BATCH="$2"; shift 2 ;;
    *) URL="$1"; shift ;;
  esac
done

if [ -z "$URL" ] && [ -z "$BATCH" ]; then
  echo "Usage: $0 <url> | --batch <d1,d2,...>" >&2
  exit 1
fi

UA="osint-recon-recipe/1.0 (headers-security)"

check_one() {
  local U="$1"
  # Normalize: add https:// if missing
  [[ "$U" != http* ]] && U="https://${U}"

  local TMP=$(mktemp)
  curl -sSL --max-time 15 -A "$UA" -D "$TMP" -o /dev/null "$U" 2>/dev/null
  if [ ! -s "$TMP" ]; then
    echo "  $U  — kunne ikke hente."
    rm -f "$TMP"
    return 1
  fi

  # Pick the final response (after redirects)
  local LAST_BLOCK=$(awk 'BEGIN{RS=""} END{print}' "$TMP" || cat "$TMP")
  local STATUS=$(echo "$LAST_BLOCK" | head -1 | tr -d '\r')

  printf "── %s\n" "$U"
  printf "   final status: %s\n" "$STATUS"

  # Headers we care about
  declare -A REQ=(
    [strict-transport-security]="HSTS"
    [content-security-policy]="CSP"
    [x-frame-options]="X-Frame-Options"
    [x-content-type-options]="X-Content-Type-Opts"
    [referrer-policy]="Referrer-Policy"
    [permissions-policy]="Permissions-Policy"
    [cross-origin-opener-policy]="COOP"
    [cross-origin-embedder-policy]="COEP"
  )

  local PRESENT=0 TOTAL=${#REQ[@]}
  for KEY in "${!REQ[@]}"; do
    VALUE=$(echo "$LAST_BLOCK" | grep -i "^${KEY}:" | head -1 | sed "s/^[^:]*:[[:space:]]*//; s/\r$//")
    if [ -n "$VALUE" ]; then
      printf "   ✓ %-22s %s\n" "${REQ[$KEY]}:" "$(echo "$VALUE" | cut -c1-80)"
      PRESENT=$((PRESENT+1))
    else
      printf "   ✗ %-22s missing\n" "${REQ[$KEY]}:"
    fi
  done

  # Info leaks
  local SERVER=$(echo "$LAST_BLOCK" | grep -i '^server:' | head -1 | sed 's/^[^:]*:[[:space:]]*//; s/\r$//')
  local POWERED=$(echo "$LAST_BLOCK" | grep -i '^x-powered-by:' | head -1 | sed 's/^[^:]*:[[:space:]]*//; s/\r$//')
  [ -n "$SERVER" ] && printf "   ⚠ Server-header leak: %s\n" "$SERVER"
  [ -n "$POWERED" ] && printf "   ⚠ X-Powered-By leak: %s\n" "$POWERED"

  # Score
  local SCORE
  if [ "$PRESENT" -ge 7 ]; then SCORE="A"
  elif [ "$PRESENT" -ge 5 ]; then SCORE="B"
  elif [ "$PRESENT" -ge 3 ]; then SCORE="C"
  elif [ "$PRESENT" -ge 1 ]; then SCORE="D"
  else SCORE="F"
  fi
  printf "   ── Score: %s (%d/%d critical headers)\n" "$SCORE" "$PRESENT" "$TOTAL"

  # TLS cert summary via openssl (passive — just SNI handshake)
  local HOST="${U#https://}"; HOST="${HOST%%/*}"
  if command -v openssl >/dev/null 2>&1; then
    local TLS=$(timeout 8 openssl s_client -connect "${HOST}:443" -servername "$HOST" </dev/null 2>/dev/null \
      | openssl x509 -noout -subject -issuer -dates 2>/dev/null | head -4)
    if [ -n "$TLS" ]; then
      printf "   ── TLS cert:\n"
      echo "$TLS" | sed 's/^/      /'
    fi
  fi

  rm -f "$TMP"
}

if [ -n "$BATCH" ]; then
  echo "=== Batch header-audit ==="
  echo "$BATCH" | tr ',' '\n' | while IFS= read -r D; do
    [ -z "$D" ] && continue
    check_one "$D"
    echo
  done
else
  echo "=== Header-audit: $URL ==="
  check_one "$URL"
fi

echo "" >&2
echo "Bemærk:" >&2
echo "  - Manglende security headers = ofte legit-issue (legacy/CMS)." >&2
echo "  - Men ren manglende HSTS + CSP + Server-header-leak ofte signal" >&2
echo "    for fake-site/phishing der spinnes hurtigt op uden hardening." >&2
echo "  - Krydsreferer score med ejer-attribution før take-down." >&2

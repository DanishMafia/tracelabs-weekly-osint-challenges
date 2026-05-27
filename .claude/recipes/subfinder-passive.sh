#!/bin/bash
# Passive subdomain enumeration. Bruger udelukkende offentlige
# datakilder — ingen DNS-brute-force, ingen probe mod target.
#
# Kilder:
#   - crt.sh (Certificate Transparency)
#   - HackerTarget (gratis tier)
#   - AlienVault OTX
#   - urlscan.io
#
# Brug:
#   ./subfinder-passive.sh example.com
#   ./subfinder-passive.sh example.com --resolve   # tilføj DNS-resolve

set -uo pipefail

DOMAIN="${1:-}"
RESOLVE="${2:-}"

if [ -z "$DOMAIN" ]; then
  echo "Usage: $0 <domain> [--resolve]" >&2
  exit 1
fi

if ! echo "$DOMAIN" | grep -qE '^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'; then
  echo "Error: ugyldigt domæne '$DOMAIN'" >&2
  exit 1
fi

UA="redteam-recon-recipe/1.0"
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

echo "=== Passive subdomain enum: $DOMAIN ===" >&2

# 1. crt.sh
echo "[crt.sh]" >&2
curl -fsSL --max-time 30 -A "$UA" "https://crt.sh/?q=%25.${DOMAIN}&output=json" 2>/dev/null \
  | jq -r '.[].name_value' 2>/dev/null \
  | tr ',' '\n' | tr '[:upper:]' '[:lower:]' \
  | sed 's/^\*\.//' \
  >> "$TMPFILE" || true

# 2. HackerTarget
echo "[hackertarget]" >&2
curl -fsSL --max-time 15 -A "$UA" \
  "https://api.hackertarget.com/hostsearch/?q=${DOMAIN}" 2>/dev/null \
  | cut -d, -f1 >> "$TMPFILE" || true

# 3. AlienVault OTX
echo "[otx.alienvault]" >&2
curl -fsSL --max-time 20 -A "$UA" \
  "https://otx.alienvault.com/api/v1/indicators/domain/${DOMAIN}/passive_dns" 2>/dev/null \
  | jq -r '.passive_dns[]?.hostname' 2>/dev/null >> "$TMPFILE" || true

# 4. urlscan.io
echo "[urlscan.io]" >&2
curl -fsSL --max-time 20 -A "$UA" \
  "https://urlscan.io/api/v1/search/?q=domain:${DOMAIN}&size=500" 2>/dev/null \
  | jq -r '.results[]?.page.domain' 2>/dev/null >> "$TMPFILE" || true

# Deduplikér + filtér til in-scope
SUBS=$(sort -u "$TMPFILE" \
       | grep -E "(^|\.)${DOMAIN//./\\.}\$" \
       | grep -vE '^\s*$' || true)

COUNT=$(echo "$SUBS" | grep -c . || true)
echo "" >&2
echo "=== Resultater: $COUNT unikke subdomæner ===" >&2

if [ "$RESOLVE" = "--resolve" ]; then
  echo "[Resolver via DoH (dns.google)...]" >&2
  echo "$SUBS" | while IFS= read -r HOST; do
    [ -z "$HOST" ] && continue
    A=$(curl -fsSL --max-time 5 "https://dns.google/resolve?name=${HOST}&type=A" 2>/dev/null \
        | jq -r '.Answer[]? | select(.type==1) | .data' 2>/dev/null \
        | head -3 | tr '\n' ',' | sed 's/,$//')
    [ -z "$A" ] && A="(none)"
    printf '%-50s  %s\n' "$HOST" "$A"
  done
else
  echo "$SUBS"
fi

echo "" >&2
echo "Bemærk: kun PASSIVE kilder. Ingen DNS-brute-force." >&2
echo "Næste skridt: kør httpx/naabu mod listen for live-probing." >&2
echo "Kun mod skriftligt autoriseret scope." >&2

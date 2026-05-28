#!/bin/bash
# whois-dk-hostmaster — slå .dk-domæner op via DK Hostmasters offentlige
# webform når port-43 WHOIS er blokeret af firewall (typisk i sandbox/
# corporate environment).
#
# Bruger DK Hostmaster's public lookup-side på HTTPS:
#   https://www.dk-hostmaster.dk/en/whois?domain=<name>
#
# DK Hostmaster har strenge T&Cs — kun til legitime opslag, ikke bulk.
#
# Subkommandoer:
#   domain <name>            Enkelt .dk-domæne
#   bulk <n1,n2,...>         Batch (med 2-sek delay per query)
#
# Brug:
#   ./whois-dk-hostmaster.sh domain natinalbanken.dk
#   ./whois-dk-hostmaster.sh bulk newbanknotes.dk,natinalbanken.dk

set -uo pipefail

CMD="${1:-}"
shift || true

ARGS=()
while [ $# -gt 0 ]; do
  ARGS+=("$1"); shift
done

if [ -z "$CMD" ]; then
  cat >&2 <<EOF
Usage: $0 <subcommand> [args]
  domain <name>          Enkelt .dk
  bulk <n1,n2,...>       Batch (med rate-limit)
EOF
  exit 1
fi

UA="Mozilla/5.0 (osint-recon-recipe whois-dk-hostmaster)"
BASE="https://www.dk-hostmaster.dk/en/whois"

fetch_whois() {
  local D="$1"
  # Strip leading .dk if user typed full URL
  D="${D#http*://}"
  D="${D%/*}"
  # Validate .dk TLD
  if [[ "$D" != *.dk ]]; then
    echo "  $D: Not a .dk domain — bruger rdap-recon.sh i stedet." >&2
    return 1
  fi
  curl -sSL --max-time 15 -A "$UA" \
    "${BASE}?domain=${D}" 2>/dev/null
}

parse_whois() {
  local HTML="$1"
  local D="$2"
  # DK Hostmaster's response uses several pre-formatted sections.
  # Look for "Domain:", "Registered:", "Registrar:", "Status:", "Hostname:" lines.
  if ! echo "$HTML" | grep -q -i 'whois\|domain:'; then
    echo "  $D: kunne ikke parse svar (form-protected eller blokeret)"
    return 1
  fi

  # Extract the pre-formatted whois block (typically inside <pre> or .whois-result)
  local BLOCK
  BLOCK=$(echo "$HTML" | sed -n '/<pre[^>]*>/,/<\/pre>/p' | sed 's/<[^>]*>//g' | head -60)
  if [ -z "$BLOCK" ]; then
    # Fallback: look for whois-class divs
    BLOCK=$(echo "$HTML" | sed -n '/whois-result\|whois-response\|whois-data/,/<\/div>/p' \
            | sed 's/<[^>]*>//g' | head -60)
  fi

  if [ -z "$BLOCK" ]; then
    echo "  $D: ingen whois-blok fundet i HTML-respons. DK Hostmaster kræver muligvis JS-render."
    echo "  → Fallback: åbn manuelt ${BASE}?domain=${D}"
    return 1
  fi

  printf "── %s\n" "$D"
  echo "$BLOCK" | sed 's/^/   /' | head -40
}

case "$CMD" in
  domain)
    D="${ARGS[0]:-}"
    [ -z "$D" ] && { echo "Usage: $0 domain <name>" >&2; exit 1; }
    echo "=== DK Hostmaster: $D ==="
    HTML=$(fetch_whois "$D")
    if [ -n "$HTML" ]; then
      parse_whois "$HTML" "$D"
    else
      echo "  Ingen respons."
    fi
    ;;

  bulk)
    LIST="${ARGS[0]:-}"
    [ -z "$LIST" ] && { echo "Usage: $0 bulk <n1,n2,...>" >&2; exit 1; }
    echo "=== DK Hostmaster bulk lookup ==="
    echo "$LIST" | tr ',' '\n' | while IFS= read -r D; do
      [ -z "$D" ] && continue
      HTML=$(fetch_whois "$D")
      if [ -n "$HTML" ]; then
        parse_whois "$HTML" "$D"
      else
        echo "── $D: ingen respons"
      fi
      sleep 2   # be polite to DK Hostmaster
    done
    ;;

  *)
    echo "Unknown subcommand: $CMD" >&2
    exit 1
    ;;
esac

echo "" >&2
echo "Bemærk:" >&2
echo "  - DK Hostmaster's T&C forbyder automatiseret bulk-mining." >&2
echo "    Brug kun til legitime, lav-volumen opslag." >&2
echo "  - Bedre løsning på sigt: kommerciel passive-DNS-feed (SecurityTrails, DNSDB)." >&2
echo "  - Ved JS-protected respons: brug headless browser ELLER manuelt lookup." >&2

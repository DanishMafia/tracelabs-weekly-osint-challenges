#!/bin/bash
# whois-dk-hostmaster — guidet .dk-domæne-lookup.
#
# Bemærk: DK Hostmaster er rebrandet til "Punktum dk" (punktum.dk).
# Deres nye web-lookup på /en/search-dk-domain er CSRF-protected
# og client-side renderet — derfor IKKE direkte scrape-bar via curl.
# Recipe'n her gør derfor følgende:
#
#   1. Validerer at input er et .dk-domæne.
#   2. Tjekker basal availability (HEAD mod punktum.dk's search-side
#      bekræfter blot at endpointet svarer — ikke selve registrant-data).
#   3. Printer den korrekte manuelle lookup-URL.
#   4. Foreslår CLI-fallbacks (`whois -h whois.punktum.dk <domain>` hvis
#      port 43 er åben).
#
# Til reelle automatiserede .dk-lookups: brug en kommerciel passive-DNS-
# feed (SecurityTrails, DNSDB, DomainTools) eller en headless browser
# (Playwright) til Punktum's form.
#
# Brug:
#   ./whois-dk-hostmaster.sh domain nationalbanken.dk
#   ./whois-dk-hostmaster.sh bulk nationalbanken.dk,nordea.dk

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
  bulk <n1,n2,...>       Batch

Recipe printer den korrekte Punktum-URL + foreslår fallbacks.
Til reel automation: brug kommerciel passive-DNS eller headless browser.
EOF
  exit 1
fi

UA="Mozilla/5.0 (osint-recon-recipe whois-dk-hostmaster)"
PUNKTUM_BASE="https://punktum.dk/en/search-dk-domain"
WHOIS_HOST="whois.punktum.dk"

lookup_one() {
  local D="$1"
  D="${D#http*://}"
  D="${D%%/*}"
  D="${D,,}"   # lowercase

  if [[ "$D" != *.dk ]]; then
    echo "── $D"
    echo "   ✗ Ikke et .dk-domæne — brug rdap-recon.sh eller standard 'whois' i stedet."
    return
  fi

  echo "── $D"

  # Step 1: confirm Punktum endpoint is reachable
  local HTTP_CODE
  HTTP_CODE=$(curl -sSL --max-time 10 -A "$UA" -o /dev/null -w "%{http_code}" \
              "${PUNKTUM_BASE}?domain=${D}" 2>/dev/null)
  echo "   Punktum web-form:   HTTP ${HTTP_CODE}"

  # Step 2: try port-43 whois (will time out in firewalled environments)
  if command -v whois >/dev/null 2>&1; then
    local WRESULT
    WRESULT=$(timeout 5 whois -h "$WHOIS_HOST" "$D" 2>&1)
    local WRC=$?
    if [ $WRC -eq 0 ] && echo "$WRESULT" | grep -q -i "registered\|domain:"; then
      echo "   Port-43 WHOIS:      OK"
      echo "$WRESULT" | grep -iE '^(domain|registered|expires|status|registrar|nserver|dnssec):' \
                     | sed 's/^/      /' | head -15
    else
      echo "   Port-43 WHOIS:      blokeret/timeout (typisk i sandbox/corporate firewall)"
    fi
  else
    echo "   Port-43 WHOIS:      'whois' CLI ikke installeret"
  fi

  # Step 3: print the canonical manual URL
  echo "   Manuel lookup:      ${PUNKTUM_BASE}?domain=${D}"
}

case "$CMD" in
  domain)
    D="${ARGS[0]:-}"
    [ -z "$D" ] && { echo "Usage: $0 domain <name>" >&2; exit 1; }
    echo "=== Punktum .dk lookup ==="
    lookup_one "$D"
    ;;

  bulk)
    LIST="${ARGS[0]:-}"
    [ -z "$LIST" ] && { echo "Usage: $0 bulk <n1,n2,...>" >&2; exit 1; }
    echo "=== Punktum .dk bulk lookup ==="
    echo "$LIST" | tr ',' '\n' | while IFS= read -r D; do
      [ -z "$D" ] && continue
      lookup_one "$D"
      sleep 1
    done
    ;;

  *)
    echo "Unknown subcommand: $CMD" >&2
    exit 1
    ;;
esac

echo "" >&2
echo "Bemærk:" >&2
echo "  - Punktum.dk's webform er CSRF-/JS-protected og kan ikke scrapes" >&2
echo "    direkte via curl. Brug et kommercielt passive-DNS-feed eller" >&2
echo "    headless browser hvis du skal automatisere over volumen." >&2
echo "  - Port 43 WHOIS er typisk blokeret af firewalls — port-43-tjek" >&2
echo "    her er best-effort." >&2

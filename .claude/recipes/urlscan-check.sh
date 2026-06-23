#!/bin/bash
# urlscan-check — søg urlscan.io for et brand/domæne.
# urlscan.io er gratis for public search (ingen API-key krævet for search).
# Brug API-key (URLSCAN_API_KEY) for højere rate-limits og private scans.
#
# Subkommandoer:
#   search <query>              Søg URL/domain — returnerer scans der matcher
#   domain <domain>             Convenience: søg på alle scans der nævner domain
#   brand <name>                Søg på brand-keyword i page-content
#   recent <domain>             Seneste 50 scans der nævner domain
#
# Brug:
#   ./urlscan-check.sh domain nationalbanken.dk
#   ./urlscan-check.sh brand "Danmarks Nationalbank"
#   ./urlscan-check.sh search 'page.domain:nationalbanken.dk'

set -uo pipefail

CMD="${1:-}"
shift || true

LIMIT=50
ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --limit) LIMIT="$2"; shift 2 ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

if [ -z "$CMD" ]; then
  cat >&2 <<EOF
Usage: $0 <subcommand> [args] [--limit N]
  search <query>     Søg urlscan.io
  domain <domain>    Søg alle scans der nævner domain
  brand <name>       Søg brand-keyword i page-content
  recent <domain>    Seneste scans der nævner domain
EOF
  exit 1
fi

UA="osint-recon-recipe/1.0 (urlscan-check)"
BASE="https://urlscan.io/api/v1"
AUTH_HDR=()
[ -n "${URLSCAN_API_KEY:-}" ] && AUTH_HDR=(-H "API-Key: ${URLSCAN_API_KEY}")

urlenc() { jq -nr --arg v "$1" '$v | @uri'; }

do_search() {
  local Q="$1"
  local QENC
  QENC=$(urlenc "$Q")
  curl -sSL --max-time 30 -A "$UA" "${AUTH_HDR[@]}" \
    "${BASE}/search/?q=${QENC}&size=${LIMIT}" 2>/dev/null
}

case "$CMD" in
  search)
    Q="${ARGS[*]:-}"
    [ -z "$Q" ] && { echo "Usage: $0 search <query>" >&2; exit 1; }
    ;;
  domain)
    D="${ARGS[0]:-}"
    [ -z "$D" ] && { echo "Usage: $0 domain <domain>" >&2; exit 1; }
    Q="page.domain:${D} OR domain:${D} OR task.domain:${D}"
    ;;
  brand)
    B="${ARGS[*]:-}"
    [ -z "$B" ] && { echo "Usage: $0 brand <name>" >&2; exit 1; }
    Q="page.title:\"${B}\" OR page.text:\"${B}\""
    ;;
  recent)
    D="${ARGS[0]:-}"
    [ -z "$D" ] && { echo "Usage: $0 recent <domain>" >&2; exit 1; }
    Q="domain:${D}"
    ;;
  *)
    echo "Unknown subcommand: $CMD" >&2
    exit 1
    ;;
esac

echo "=== urlscan: $Q (limit $LIMIT) ===" >&2
BODY=$(do_search "$Q")
TOTAL=$(echo "$BODY" | jq -r '.total // 0')
echo "Total matches: $TOTAL" >&2
echo

if [ "$TOTAL" = "0" ] || [ "$TOTAL" = "null" ]; then
  echo "(ingen scans matchede)"
  exit 0
fi

echo "$BODY" | jq -r '.results[]? |
  "── \(.task.time // "?")  \(.page.url // .task.url // "?")
   page.domain:    \(.page.domain // "-")
   page.ip:        \(.page.ip // "-")  (\(.page.country // "-") / \(.page.asn // "-"))
   page.server:    \(.page.server // "-")
   page.title:     \((.page.title // "") | .[0:80])
   scan ID:        \(._id)
   scan URL:       https://urlscan.io/result/\(._id)/"'

echo "" >&2
echo "Bemærk:" >&2
echo "  - urlscan.io-data er public — alle scans er synlige medmindre markeret private." >&2
echo "  - Klik IKKE direkte på fundne URL'er; brug urlscan-screenshots eller arkiv." >&2

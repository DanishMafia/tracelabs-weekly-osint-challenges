#!/bin/bash
# ct-search — direkte search mod crt.sh (Certificate Transparency).
# Bredere/mere fokuseret end subfinder-passive — søger også på
# wildcards og organisationsnavne.
#
# Brug:
#   ./ct-search.sh nationalbanken.dk            # alle cert-issuances
#   ./ct-search.sh '%nationalbanken%'           # wildcard
#   ./ct-search.sh nationalbanken.dk --recent 90   # kun seneste 90 dage
#   ./ct-search.sh --org "Danmarks Nationalbank"   # søg på Subject Organization

set -uo pipefail

QUERY=""
ORG=""
RECENT_DAYS=0

while [ $# -gt 0 ]; do
  case "$1" in
    --org)    ORG="$2"; shift 2 ;;
    --recent) RECENT_DAYS="$2"; shift 2 ;;
    *) QUERY="$1"; shift ;;
  esac
done

if [ -z "$QUERY" ] && [ -z "$ORG" ]; then
  echo "Usage: $0 <domain-or-wildcard> [--recent N] [--org <name>]" >&2
  exit 1
fi

UA="osint-recon-recipe/1.0 (ct-search)"

if [ -n "$ORG" ]; then
  QENC=$(jq -nr --arg v "$ORG" '$v | @uri')
  URL="https://crt.sh/?O=${QENC}&output=json"
  LABEL="org=$ORG"
else
  QENC=$(jq -nr --arg v "$QUERY" '$v | @uri')
  URL="https://crt.sh/?q=${QENC}&output=json"
  LABEL="query=$QUERY"
fi

echo "=== crt.sh: $LABEL ===" >&2
BODY=$(curl -sSL --max-time 60 -A "$UA" "$URL" 2>/dev/null)

if [ -z "$BODY" ] || [ "$BODY" = "[]" ]; then
  echo "(ingen certifikater fundet)"
  exit 0
fi

# Filter by recent days if requested
if [ "$RECENT_DAYS" -gt 0 ]; then
  CUTOFF=$(date -u -d "$RECENT_DAYS days ago" +%Y-%m-%dT00:00:00 2>/dev/null \
           || date -u -v-${RECENT_DAYS}d +%Y-%m-%dT00:00:00)
  BODY=$(echo "$BODY" | jq --arg c "$CUTOFF" '[.[] | select(.entry_timestamp >= $c)]')
fi

TOTAL=$(echo "$BODY" | jq -r 'length')
echo "Certs fundet: $TOTAL (recent=${RECENT_DAYS:-all} dage)" >&2
echo

# Unique subdomains
echo "[Unikke navne i SAN/CN]"
echo "$BODY" | jq -r '.[].name_value' \
  | tr ',' '\n' | tr -d ' ' \
  | grep -vE '^\*\.' | grep -v '^$' \
  | sort -u \
  | head -100

echo
echo "[Seneste 15 issuances]"
echo "$BODY" | jq -r '. | sort_by(.entry_timestamp) | reverse | .[0:15] | .[] |
  "── \(.entry_timestamp // "?")
   issuer:    \(.issuer_name // "?" | .[0:80])
   names:     \(.name_value | gsub("\n"; ", ") | .[0:120])
   cert ID:   \(.id // "?")  → https://crt.sh/?id=\(.id // "?")"'

echo "" >&2
echo "Bemærk:" >&2
echo "  - crt.sh er public Certificate Transparency. Ingen auth krævet." >&2
echo "  - Brug --recent N for at fokusere på nye, mistænkelige issuances." >&2
echo "  - Pivot: send fundne navne videre til subfinder-passive / url-recon." >&2

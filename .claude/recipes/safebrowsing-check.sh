#!/bin/bash
# safebrowsing-check — slå en eller flere URLs op mod Google Safe Browsing v4.
# Kræver SAFEBROWSING_API_KEY (Google Cloud Console — gratis tier 10k/dag).
# Docs: https://developers.google.com/safe-browsing/v4/
#
# Subkommandoer:
#   url <url>                Single URL-lookup
#   batch <url1,url2,...>    Batch (max 500 per call)
#   stdin                    Læs URLs fra stdin (en pr. linje)
#
# Threat-types der tjekkes:
#   MALWARE, SOCIAL_ENGINEERING (phishing), UNWANTED_SOFTWARE,
#   POTENTIALLY_HARMFUL_APPLICATION
#
# Brug:
#   export SAFEBROWSING_API_KEY=<key>
#   ./safebrowsing-check.sh url https://nationalbanken.xyz
#   ./safebrowsing-check.sh batch https://a.com,https://b.com
#   cat urls.txt | ./safebrowsing-check.sh stdin

set -uo pipefail

CMD="${1:-}"
shift || true

KEY="${SAFEBROWSING_API_KEY:-${GOOGLE_API_KEY:-}}"
ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --key) KEY="$2"; shift 2 ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

if [ -z "$CMD" ]; then
  cat >&2 <<EOF
Usage: $0 <subcommand> [args]
  url <url>              Single URL
  batch <u1,u2,...>      Batch (max 500 per call)
  stdin                  URLs from stdin (one per line)

Krav:
  export SAFEBROWSING_API_KEY=<key fra Google Cloud Console>
  (https://console.cloud.google.com/apis/api/safebrowsing.googleapis.com)
EOF
  exit 1
fi

if [ -z "$KEY" ]; then
  echo "Error: \$SAFEBROWSING_API_KEY (eller --key) ikke sat." >&2
  echo "Hent gratis key: https://console.cloud.google.com/apis/api/safebrowsing.googleapis.com" >&2
  exit 1
fi

UA="osint-recon-recipe/1.0 (safebrowsing-check)"
API="https://safebrowsing.googleapis.com/v4/threatMatches:find?key=${KEY}"

# Build JSON request body
build_request() {
  local URLS_JSON="$1"
  cat <<EOF
{
  "client": {
    "clientId": "osint-recon-recipe",
    "clientVersion": "1.0"
  },
  "threatInfo": {
    "threatTypes": ["MALWARE", "SOCIAL_ENGINEERING", "UNWANTED_SOFTWARE", "POTENTIALLY_HARMFUL_APPLICATION"],
    "platformTypes": ["ANY_PLATFORM"],
    "threatEntryTypes": ["URL"],
    "threatEntries": ${URLS_JSON}
  }
}
EOF
}

check_urls() {
  local URLS_JSON="$1"
  local BODY
  BODY=$(build_request "$URLS_JSON")
  RESP=$(curl -sSL --max-time 20 -A "$UA" \
              -H "Content-Type: application/json" \
              -X POST --data "$BODY" \
              -w '\n%{http_code}' \
              "$API")
  CODE=$(echo "$RESP" | tail -n1)
  RESP_BODY=$(echo "$RESP" | sed '$d')
  case "$CODE" in
    200)
      if [ -z "$RESP_BODY" ] || [ "$RESP_BODY" = "{}" ]; then
        echo "  ✓ Ingen threat-matches"
        return 0
      fi
      echo "$RESP_BODY" | jq -r '
        if (.matches | length) > 0 then
          "⚠ \(.matches | length) MATCHES:",
          (.matches[] | "    URL:    \(.threat.url)
    Type:   \(.threatType)
    Platform: \(.platformType)
    Cache:  \(.cacheDuration // "?")")
        else
          "  ✓ Ingen threat-matches"
        end'
      ;;
    400) echo "  Fejl (400): $RESP_BODY" >&2; return 1 ;;
    401|403) echo "  Auth-fejl ($CODE) — tjek API-key og at Safe Browsing API er enabled." >&2; return 1 ;;
    429) echo "  Rate-limited (429)" >&2; return 1 ;;
    *) echo "  Uventet HTTP $CODE: $RESP_BODY" >&2; return 1 ;;
  esac
}

case "$CMD" in
  url)
    U="${ARGS[0]:-}"
    [ -z "$U" ] && { echo "Usage: $0 url <url>" >&2; exit 1; }
    echo "=== Safe Browsing: $U ==="
    URLS=$(jq -nc --arg u "$U" '[{url: $u}]')
    check_urls "$URLS"
    ;;

  batch)
    LIST="${ARGS[0]:-}"
    [ -z "$LIST" ] && { echo "Usage: $0 batch <u1,u2,...>" >&2; exit 1; }
    echo "=== Safe Browsing batch ==="
    URLS=$(echo "$LIST" | tr ',' '\n' | jq -R . | jq -s '[.[] | select(length > 0) | {url: .}]')
    COUNT=$(echo "$URLS" | jq 'length')
    echo "URLs i batch: $COUNT"
    check_urls "$URLS"
    ;;

  stdin)
    echo "=== Safe Browsing stdin batch ==="
    URLS=$(jq -R . | jq -s '[.[] | select(length > 0) | {url: .}]')
    COUNT=$(echo "$URLS" | jq 'length')
    echo "URLs læst: $COUNT"
    check_urls "$URLS"
    ;;

  *)
    echo "Unknown subcommand: $CMD" >&2
    exit 1
    ;;
esac

echo "" >&2
echo "Bemærk:" >&2
echo "  - Safe Browsing v4 har 10k requests/dag på gratis tier." >&2
echo "  - Batch er væsentlig mere effektiv end single (max 500 URLs/call)." >&2
echo "  - For continuous monitoring: brug Update API v4 (lokal cache)." >&2

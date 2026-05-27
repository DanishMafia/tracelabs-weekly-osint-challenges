#!/bin/bash
# socmint-meta-ads — søg Meta Ad Library efter brand-keywords / annoncørnavne.
# Public REST API, men kræver en META_AD_LIBRARY_TOKEN (Facebook App access-token).
# Gratis: opret en Meta dev app, hent system-user access-token.
# Docs: https://www.facebook.com/ads/library/api/
#
# Subkommandoer:
#   search <query>              Søg politiske/finansielle annoncer der nævner brand
#   advertiser <page-id>        Alle aktive annoncer fra en specifik side
#
# Brug:
#   export META_AD_LIBRARY_TOKEN=<token>
#   ./socmint-meta-ads.sh search "Danmarks Nationalbank" --country DK
#   ./socmint-meta-ads.sh search "Nationalbanken investment"

set -uo pipefail

CMD="${1:-}"
shift || true

COUNTRY="DK"
LIMIT=50
PLATFORM="all"
AD_TYPE="ALL"
ACTIVE="all"
ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --country)  COUNTRY="$2"; shift 2 ;;
    --limit)    LIMIT="$2"; shift 2 ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    --type)     AD_TYPE="$2"; shift 2 ;;
    --active)   ACTIVE="$2"; shift 2 ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

if [ -z "$CMD" ]; then
  cat >&2 <<EOF
Usage: $0 <subcommand> [args]
  search <query>           Søg annoncer
  advertiser <page-id>     Annoncer fra side-ID

Flags:
  --country <code>         Default: DK (kan være US, GB, DE, etc.)
  --limit <n>              Default: 50 (max 250)
  --type <ALL|POLITICAL_AND_ISSUE_ADS>  Default: ALL
  --active <all|active|inactive>        Default: all

Krav:
  export META_AD_LIBRARY_TOKEN=<token fra Meta Dev>
EOF
  exit 1
fi

TOKEN="${META_AD_LIBRARY_TOKEN:-}"
if [ -z "$TOKEN" ]; then
  echo "Error: \$META_AD_LIBRARY_TOKEN ikke sat." >&2
  echo "Hent en token: https://developers.facebook.com/docs/marketing-api/access" >&2
  exit 1
fi

UA="osint-recon-recipe/1.0 (socmint-meta-ads)"
BASE="https://graph.facebook.com/v19.0/ads_archive"
FIELDS="id,page_id,page_name,ad_creative_bodies,ad_creative_link_titles,ad_creative_link_captions,ad_creative_link_descriptions,ad_delivery_start_time,ad_delivery_stop_time,ad_snapshot_url,impressions,spend,currency,languages,publisher_platforms,ad_creation_time"

urlenc() { jq -nr --arg v "$1" '$v | @uri'; }

case "$CMD" in
  search)
    Q="${ARGS[*]:-}"
    [ -z "$Q" ] && { echo "Usage: $0 search <query>" >&2; exit 1; }
    QENC=$(urlenc "$Q")
    URL="${BASE}?search_terms=${QENC}&ad_reached_countries=[%22${COUNTRY}%22]&ad_type=${AD_TYPE}&ad_active_status=${ACTIVE}&fields=${FIELDS}&limit=${LIMIT}&access_token=${TOKEN}"
    echo "=== Meta Ad Library: \"$Q\" (${COUNTRY}, type=${AD_TYPE}, status=${ACTIVE}) ==="
    RESP=$(curl -sSL --max-time 30 -A "$UA" "$URL")
    if echo "$RESP" | jq -e '.error' >/dev/null 2>&1; then
      echo "Fejl:"
      echo "$RESP" | jq -r '.error | "  \(.type): \(.message) (code=\(.code))"'
      exit 1
    fi
    HITS=$(echo "$RESP" | jq -r '.data | length' 2>/dev/null)
    echo "Hits: $HITS"
    echo "$RESP" | jq -r '.data[]? |
      "── ad-id: \(.id)  page: \"\(.page_name // "?")\"  (page-id \(.page_id // "?"))
   started:    \(.ad_delivery_start_time // "?")
   stopped:    \(.ad_delivery_stop_time // "(aktiv)")
   platforms:  \((.publisher_platforms // []) | join(", "))
   languages:  \((.languages // []) | join(", "))
   spend:      \(.spend // "?")  currency: \(.currency // "?")
   impressions: \(.impressions // "?")
   body:       \((.ad_creative_bodies // [])[0] // "(none)" | gsub("\n"; " ⏎ ") | .[0:240])
   snapshot:   \(.ad_snapshot_url // "?")"'
    ;;

  advertiser)
    PID="${ARGS[0]:-}"
    [ -z "$PID" ] && { echo "Usage: $0 advertiser <page-id>" >&2; exit 1; }
    URL="${BASE}?search_page_ids=[${PID}]&ad_reached_countries=[%22${COUNTRY}%22]&ad_type=${AD_TYPE}&ad_active_status=${ACTIVE}&fields=${FIELDS}&limit=${LIMIT}&access_token=${TOKEN}"
    echo "=== Meta Ad Library: page-id ${PID} ==="
    RESP=$(curl -sSL --max-time 30 -A "$UA" "$URL")
    echo "$RESP" | jq -r '.data[]? |
      "── \(.id)  started \(.ad_delivery_start_time // "?")  body: \((.ad_creative_bodies // [])[0] // "(none)" | .[0:200])"'
    ;;

  *)
    echo "Unknown subcommand: $CMD" >&2
    exit 1
    ;;
esac

echo "" >&2
echo "Bemærk:" >&2
echo "  - Meta Ad Library indeholder politiske + issue-annoncer permanent;" >&2
echo "    kommercielle annoncer kun mens aktive." >&2
echo "  - Snapshot-URLs er statiske og kan arkiveres med archive-url.sh." >&2
echo "  - Krydsreferer page_id mod Meta Business Pages." >&2

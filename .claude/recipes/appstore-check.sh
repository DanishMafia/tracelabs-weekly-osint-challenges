#!/bin/bash
# appstore-check — søg Apple App Store + Google Play efter apps der
# claimer brand-tilknytning. Vigtigt for brand-protection mod fake
# banking-apps. Apple's iTunes Search API er public + ingen auth.
# Google Play scrapes via deres public-facing søgning (HTML).
#
# Subkommandoer:
#   apple <query>            iTunes Search API
#   google <query>           Google Play web-search via deres public html
#   bank-check <brand>       Forberedt søgning på "<brand> bank|banking|app"
#   verify <bundle-id>       Apple bundle ID details
#
# Brug:
#   ./appstore-check.sh apple "Danmarks Nationalbank"
#   ./appstore-check.sh google "Nationalbanken"
#   ./appstore-check.sh bank-check "Nationalbanken"

set -uo pipefail

CMD="${1:-}"
shift || true

COUNTRY="dk"
LIMIT=20
ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --country) COUNTRY="$2"; shift 2 ;;
    --limit)   LIMIT="$2"; shift 2 ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

if [ -z "$CMD" ]; then
  cat >&2 <<EOF
Usage: $0 <subcommand> [args]
  apple <query>        iTunes Search API
  google <query>       Google Play HTML-search
  bank-check <brand>   Bredt scan: "<brand>", "<brand> bank", "<brand> banking", "<brand> app"
  verify <bundle-id>   Apple bundle-ID detaljer

Flags:
  --country <code>     Default: dk
  --limit <n>          Default: 20
EOF
  exit 1
fi

UA_APPLE="osint-recon-recipe/1.0 (appstore-check)"
UA_BROWSER="Mozilla/5.0 (X11; Linux x86_64) appstore-check/1.0"
urlenc() { jq -nr --arg v "$1" '$v | @uri'; }

apple_search() {
  local Q="$1"
  local QENC=$(urlenc "$Q")
  local URL="https://itunes.apple.com/search?term=${QENC}&country=${COUNTRY}&media=software&limit=${LIMIT}"
  curl -sSL --max-time 15 -A "$UA_APPLE" "$URL"
}

google_play_search() {
  local Q="$1"
  local QENC=$(urlenc "$Q")
  local URL="https://play.google.com/store/search?q=${QENC}&c=apps&hl=da&gl=${COUNTRY}"
  curl -sSL --max-time 15 -A "$UA_BROWSER" "$URL"
}

print_apple_results() {
  local BODY="$1"
  local COUNT=$(echo "$BODY" | jq -r '.resultCount // 0')
  echo "  resultCount: $COUNT"
  echo "$BODY" | jq -r '.results[]? |
    "── \(.trackName)  [\(.primaryGenreName // "?")]
   bundleId:    \(.bundleId // "?")
   seller:      \(.sellerName // "?")
   artist:      \(.artistName // "?")
   price:       \((.price // 0) | tostring) \(.currency // "")
   released:    \(.releaseDate // "?")
   updated:     \(.currentVersionReleaseDate // "?")
   rating:      \(.averageUserRating // "n/a") (\(.userRatingCount // 0) reviews)
   url:         \(.trackViewUrl // "?")"' | head -120
}

case "$CMD" in
  apple)
    Q="${ARGS[*]:-}"
    [ -z "$Q" ] && { echo "Usage: $0 apple <query>" >&2; exit 1; }
    echo "=== Apple App Store: \"$Q\" (country=$COUNTRY) ==="
    BODY=$(apple_search "$Q")
    print_apple_results "$BODY"
    ;;

  google)
    Q="${ARGS[*]:-}"
    [ -z "$Q" ] && { echo "Usage: $0 google <query>" >&2; exit 1; }
    echo "=== Google Play: \"$Q\" (country=$COUNTRY) ==="
    HTML=$(google_play_search "$Q")
    # Google Play HTML er JS-heavy, men har stadig nogle app-detaljer i HTML
    # Udtræk pakke-navne + titler
    echo "$HTML" | grep -oE '/store/apps/details\?id=[a-zA-Z0-9._]+' | sort -u | head -${LIMIT} \
      | while read -r PATH_; do
          ID="${PATH_#*id=}"
          printf "  ── %s\n     https://play.google.com%s\n" "$ID" "$PATH_"
        done
    if [ -z "$(echo "$HTML" | grep -oE '/store/apps/details' | head -1)" ]; then
      echo "  (Google Play returnerede ingen synlige app-links i HTML — JS-rendering)"
    fi
    ;;

  bank-check)
    B="${ARGS[*]:-}"
    [ -z "$B" ] && { echo "Usage: $0 bank-check <brand>" >&2; exit 1; }
    echo "===== App store-brand-check: \"$B\" ====="
    for SUFFIX in "" " bank" " banking" " app" " login" " mobile"; do
      Q="${B}${SUFFIX}"
      echo
      echo "--- Apple: \"$Q\" ---"
      BODY=$(apple_search "$Q")
      COUNT=$(echo "$BODY" | jq -r '.resultCount // 0')
      if [ "$COUNT" -gt 0 ]; then
        echo "$BODY" | jq -r '.results[]? | "  \(.trackName)  [\(.bundleId // "?")]  seller=\(.sellerName // "?")"'
      else
        echo "  (ingen hits)"
      fi
    done
    echo
    echo "--- Google Play: \"$B bank\" ---"
    HTML=$(google_play_search "$B bank")
    echo "$HTML" | grep -oE '/store/apps/details\?id=[a-zA-Z0-9._]+' | sort -u | head -10 \
      | sed 's|^|  https://play.google.com|'
    ;;

  verify)
    BID="${ARGS[0]:-}"
    [ -z "$BID" ] && { echo "Usage: $0 verify <bundle-id>" >&2; exit 1; }
    QENC=$(urlenc "$BID")
    URL="https://itunes.apple.com/lookup?bundleId=${BID}&country=${COUNTRY}"
    BODY=$(curl -sSL --max-time 15 -A "$UA_APPLE" "$URL")
    print_apple_results "$BODY"
    ;;

  *)
    echo "Unknown subcommand: $CMD" >&2
    exit 1
    ;;
esac

echo "" >&2
echo "Bemærk:" >&2
echo "  - Apple iTunes Search API er gratis + ingen auth, men rate-limited." >&2
echo "  - Google Play HTML-scrape er fragile — fungerer typisk men kan brydes." >&2
echo "  - Fake banking-apps i Google Play: brug --country dk for DK-fokus." >&2
echo "  - Take-down: developer.apple.com/legal/internet-services / play.google.com/legal" >&2

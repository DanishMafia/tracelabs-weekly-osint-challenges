#!/bin/bash
# socmint-telegram — passiv Telegram-recon mod offentlige kanaler.
# Telegram har INGEN public search-API uden Bot/MTProto-auth.
# Vi bruger:
#   1. t.me/<channel> public previews (HTML scrape af deep-link)
#   2. tgstat.com / lyzem.com indexers (HTTP-only, public)
#   3. Google site-search som fallback
#
# Subkommandoer:
#   channel <name>       Hent t.me/<name> public preview-metadata
#   index-search <q>     Google site:t.me search via DuckDuckGo HTML
#   check-channels <n,n> Batch-eksistens-check
#
# Brug:
#   ./socmint-telegram.sh channel nationalbanken
#   ./socmint-telegram.sh index-search "Danmarks Nationalbank"
#   ./socmint-telegram.sh check-channels nationalbanken,dnb,danmarks_nationalbank

set -uo pipefail

CMD="${1:-}"
shift || true

LIMIT=20
ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --limit) LIMIT="$2"; shift 2 ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

if [ -z "$CMD" ]; then
  cat >&2 <<EOF
Usage: $0 <subcommand> [args]
  channel <name>          Hent t.me/<name>-preview-metadata
  index-search <query>    DuckDuckGo HTML-fallback over t.me-domæner
  check-channels <n1,n2>  Batch eksistens-check
EOF
  exit 1
fi

UA="Mozilla/5.0 (osint-recon-recipe socmint-telegram)"

fetch_channel_preview() {
  local NAME="$1"
  # t.me/<name> returnerer HTML med OG-tags og preview-data
  curl -sSL --max-time 10 -A "$UA" "https://t.me/${NAME}" 2>/dev/null
}

parse_channel_meta() {
  local HTML="$1"
  local NAME="$2"
  # Telegram returnerer 200 selv for ikke-eksisterende — tjek for marker
  if echo "$HTML" | grep -q 'tgme_page_extra'; then
    local TITLE=$(echo "$HTML" | grep -oE '<meta property="og:title" content="[^"]*"' | head -1 | sed 's/.*content="//; s/"$//')
    local DESC=$(echo "$HTML" | grep -oE '<meta property="og:description" content="[^"]*"' | head -1 | sed 's/.*content="//; s/"$//')
    local IMG=$(echo "$HTML" | grep -oE '<meta property="og:image" content="[^"]*"' | head -1 | sed 's/.*content="//; s/"$//')
    local SUBS=$(echo "$HTML" | grep -oE 'tgme_page_extra">[^<]*' | head -1 | sed 's/.*>//; s/&nbsp;/ /g')
    local TYPE=$(echo "$HTML" | grep -oE '"og:type" content="[^"]*"' | head -1 | sed 's/.*content="//; s/"$//')
    printf "  Name:    %s\n" "$NAME"
    printf "  Title:   %s\n" "$TITLE"
    printf "  Type:    %s\n" "$TYPE"
    printf "  Subs:    %s\n" "$SUBS"
    printf "  Desc:    %s\n" "${DESC:0:200}"
    printf "  Image:   %s\n" "$IMG"
    return 0
  elif echo "$HTML" | grep -q 'tgme_page_title'; then
    # Page exists but is empty / private — still extract what we can
    local TITLE=$(echo "$HTML" | grep -oE '<meta property="og:title" content="[^"]*"' | head -1 | sed 's/.*content="//; s/"$//')
    printf "  Name:    %s\n" "$NAME"
    printf "  Title:   %s  (begrænset preview)\n" "$TITLE"
    return 0
  else
    return 1
  fi
}

case "$CMD" in
  channel)
    N="${ARGS[0]:-}"
    [ -z "$N" ] && { echo "Usage: $0 channel <name>" >&2; exit 1; }
    echo "=== t.me/${N} ==="
    HTML=$(fetch_channel_preview "$N")
    if ! parse_channel_meta "$HTML" "$N"; then
      echo "  Kanal/bruger ikke fundet eller fuldt privat."
    fi
    ;;

  index-search)
    Q="${ARGS[*]:-}"
    [ -z "$Q" ] && { echo "Usage: $0 index-search <query>" >&2; exit 1; }
    # Use DuckDuckGo HTML endpoint as a search-engine fallback
    QFULL="site:t.me ${Q}"
    QENC=$(jq -nr --arg v "$QFULL" '$v | @uri')
    URL="https://html.duckduckgo.com/html/?q=${QENC}"
    echo "=== DDG site:t.me \"$Q\" ==="
    RESP=$(curl -sSL --max-time 15 -A "$UA" "$URL")
    echo "$RESP" \
      | grep -oE 'href="[^"]*t\.me/[^"]+"|class="result__title">[^<]*' \
      | head -30 \
      | sed 's/href="//; s/"$//; s/class="result__title">//' \
      | awk 'NR%2==1{u=$0; next} {print "  " $0 " → " u}'
    ;;

  check-channels)
    LIST="${ARGS[0]:-}"
    [ -z "$LIST" ] && { echo "Usage: $0 check-channels <n1,n2,...>" >&2; exit 1; }
    printf "%-40s  %-9s  %s\n" "Channel" "Status" "Title/Subs"
    echo "$LIST" | tr ',' '\n' | while IFS= read -r N; do
      [ -z "$N" ] && continue
      HTML=$(fetch_channel_preview "$N")
      if echo "$HTML" | grep -q 'tgme_page_extra'; then
        TITLE=$(echo "$HTML" | grep -oE '<meta property="og:title" content="[^"]*"' | head -1 | sed 's/.*content="//; s/"$//')
        SUBS=$(echo "$HTML" | grep -oE 'tgme_page_extra">[^<]*' | head -1 | sed 's/.*>//')
        printf "%-40s  %-9s  %s [%s]\n" "$N" "EXISTS" "${TITLE:0:50}" "${SUBS:0:30}"
      elif echo "$HTML" | grep -q 'tgme_page_title'; then
        TITLE=$(echo "$HTML" | grep -oE '<meta property="og:title" content="[^"]*"' | head -1 | sed 's/.*content="//; s/"$//')
        printf "%-40s  %-9s  %s\n" "$N" "PRIV" "$TITLE"
      else
        printf "%-40s  %-9s  %s\n" "$N" "FREE" "-"
      fi
    done
    ;;

  *)
    echo "Unknown subcommand: $CMD" >&2
    exit 1
    ;;
esac

echo "" >&2
echo "Bemærk:" >&2
echo "  - Telegram-recon er fundamentally begrænset uden MTProto/Bot-auth." >&2
echo "  - Public previews viser kun seneste posts hvis kanalen er offentlig." >&2
echo "  - For dybere content-monitoring: kør en Bot-konto via tdlib (eskaleret SOW)." >&2

#!/bin/bash
# socmint-mastodon — Fediverse-SOCMINT via Mastodon public API.
# Mastodon er decentraliseret: hver instance har egen API. Søgning
# kræver typisk auth, men public timelines + lookup virker uden.
#
# Subkommandoer:
#   lookup <handle@instance>            Profil-eksistens og metadata
#   instance-search <instance> <query>  Public-timeline-søgning på én instance
#   public-feed <instance>              Public local timeline
#   check-handles <handle@instance,...> Batch handle-eksistens
#
# Brug:
#   ./socmint-mastodon.sh lookup user@mastodon.social
#   ./socmint-mastodon.sh check-handles dnb@mastodon.social,nationalbanken@mas.to
#   ./socmint-mastodon.sh instance-search mastodon.social "Nationalbanken"

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
  lookup <handle@instance>            Profil-metadata
  instance-search <instance> <query>  Søg public-timeline
  public-feed <instance>              Local timeline
  check-handles <h1,h2,...>           Batch eksistens-check
EOF
  exit 1
fi

UA="osint-recon-recipe/1.0 (socmint-mastodon)"

split_handle() {
  # handle@instance → echo "handle instance"
  local h="$1"
  echo "${h%@*}" "${h##*@}"
}

lookup_account() {
  # lookup handle@instance using the instance's WebFinger + lookup API
  local FULL="$1"
  local USER INSTANCE
  read -r USER INSTANCE <<< "$(split_handle "$FULL")"
  # Try Mastodon lookup endpoint (no auth needed in v4)
  curl -sSL --max-time 8 -A "$UA" \
    "https://${INSTANCE}/api/v1/accounts/lookup?acct=${USER}" 2>/dev/null
}

case "$CMD" in
  lookup)
    H="${ARGS[0]:-}"
    [ -z "$H" ] && { echo "Usage: $0 lookup <handle@instance>" >&2; exit 1; }
    RESP=$(lookup_account "$H")
    if echo "$RESP" | jq -e '.id' >/dev/null 2>&1; then
      echo "$RESP" | jq -r '
        "Acct:       \(.acct)",
        "Display:    \(.display_name // "(none)")",
        "ID:         \(.id)",
        "Created:    \((.created_at // "?")[:10])",
        "Followers:  \(.followers_count // 0)",
        "Following:  \(.following_count // 0)",
        "Statuses:   \(.statuses_count // 0)",
        "Bot:        \(.bot // false)",
        "Discoverable: \(.discoverable // false)",
        "Verified-fields: \((.fields // []) | map(select(.verified_at != null)) | length)",
        "",
        "Note:",
        ((.note // "") | gsub("<[^>]+>"; "") | .[0:300])'
    else
      echo "$H → ikke fundet"
      echo "$RESP" | head -c 400
    fi
    ;;

  instance-search)
    INSTANCE="${ARGS[0]:-}"
    Q="${ARGS[@]:1}"
    [ -z "$INSTANCE" ] || [ -z "$Q" ] && { echo "Usage: $0 instance-search <instance> <query>" >&2; exit 1; }
    QENC=$(jq -nr --arg v "$Q" '$v | @uri')
    # v2 search requires auth — fall back to hashtag-search which is public
    if [[ "$Q" == \#* ]]; then
      TAG="${Q#\#}"
      URL="https://${INSTANCE}/api/v1/timelines/tag/${TAG}?limit=${LIMIT}"
    else
      URL="https://${INSTANCE}/api/v2/search?q=${QENC}&type=statuses&limit=${LIMIT}"
    fi
    echo "=== ${INSTANCE} search: \"$Q\" ==="
    RESP=$(curl -sSL --max-time 15 -A "$UA" "$URL")
    if echo "$RESP" | jq -e 'type=="array"' >/dev/null 2>&1; then
      # tag-timeline returns array
      echo "$RESP" | jq -r '.[]? |
        "── @\(.account.acct)  \(.created_at[:16])
   text: \((.content // "" | gsub("<[^>]+>"; "")) | gsub("\n"; " ⏎ ") | .[0:200])
   ❤ \(.favourites_count // 0)  🔁 \(.reblogs_count // 0)  💬 \(.replies_count // 0)
   url: \(.url // .uri // "?")"'
    elif echo "$RESP" | jq -e '.statuses' >/dev/null 2>&1; then
      echo "$RESP" | jq -r '.statuses[]? |
        "── @\(.account.acct)  \(.created_at[:16])
   text: \((.content // "" | gsub("<[^>]+>"; "")) | gsub("\n"; " ⏎ ") | .[0:200])"'
    else
      echo "(ingen resultater eller endpoint kræver auth)"
      echo "$RESP" | head -c 400
    fi
    ;;

  public-feed)
    INSTANCE="${ARGS[0]:-}"
    [ -z "$INSTANCE" ] && { echo "Usage: $0 public-feed <instance>" >&2; exit 1; }
    URL="https://${INSTANCE}/api/v1/timelines/public?local=true&limit=${LIMIT}"
    echo "=== ${INSTANCE} local public timeline ==="
    curl -sSL --max-time 15 -A "$UA" "$URL" | jq -r '.[]? |
      "── @\(.account.acct)  \(.created_at[:16])
   text: \((.content // "" | gsub("<[^>]+>"; "")) | gsub("\n"; " ⏎ ") | .[0:200])"'
    ;;

  check-handles)
    LIST="${ARGS[0]:-}"
    [ -z "$LIST" ] && { echo "Usage: $0 check-handles <h1@inst,h2@inst,...>" >&2; exit 1; }
    printf "%-40s  %-9s  %-12s  %-10s  %s\n" "Handle" "Status" "Created" "Followers" "Statuses"
    echo "$LIST" | tr ',' '\n' | while IFS= read -r H; do
      [ -z "$H" ] && continue
      RESP=$(lookup_account "$H")
      if echo "$RESP" | jq -e '.id' >/dev/null 2>&1; then
        echo "$RESP" | jq -r "[\"$H\", \"EXISTS\", (.created_at // \"?\")[:10], (.followers_count // 0), (.statuses_count // 0)] | @tsv" \
          | awk -F'\t' '{printf "%-40s  %-9s  %-12s  %-10s  %s\n", $1, $2, $3, $4, $5}'
      else
        printf "%-40s  %-9s  %-12s  %-10s  %s\n" "$H" "FREE/404" "-" "-" "-"
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
echo "  - Mastodon-search kræver auth på de fleste instances (v2 search)." >&2
echo "  - Hashtag-timeline og account-lookup virker uden auth." >&2
echo "  - For fuld Fediverse-search: kør mod flere instances (mastodon.social, fosstodon.org, m.fl.)." >&2

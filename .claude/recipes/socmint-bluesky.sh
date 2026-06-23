#!/bin/bash
# socmint-bluesky — SOCMINT mod Bluesky (AT Protocol).
# Bluesky's public API kræver ingen auth for read-operationer.
#
# Subkommandoer:
#   profile <handle>             Profil-metadata (eksistens-check + følgere)
#   search-posts <query>          Post-søgning på tværs af Bluesky
#   search-actors <query>         Profil-/aktør-søgning
#   feed <handle>                 Seneste posts fra en konto
#   check-handles <handle,...>    Batch-eksistens-check af kandidat-handles
#
# Brug:
#   ./socmint-bluesky.sh profile nationalbanken.dk
#   ./socmint-bluesky.sh search-posts "nationalbanken scam"
#   ./socmint-bluesky.sh search-actors "Danmarks Nationalbank"
#   ./socmint-bluesky.sh check-handles ckth.bsky.social,skro.bsky.social

set -uo pipefail

CMD="${1:-}"
shift || true

LIMIT=25
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
  profile <handle>             Profil-metadata
  search-posts <query>         Post-søgning
  search-actors <query>        Profil-søgning
  feed <handle>                Seneste posts
  check-handles <h1,h2,...>    Batch-eksistens
EOF
  exit 1
fi

UA="osint-recon-recipe/1.0 (socmint-bluesky)"
BASE="https://public.api.bsky.app/xrpc"

urlenc() { jq -nr --arg v "$1" '$v | @uri'; }

case "$CMD" in
  profile)
    H="${ARGS[0]:-}"
    [ -z "$H" ] && { echo "Usage: $0 profile <handle>" >&2; exit 1; }
    RESP=$(curl -sSL --max-time 10 -A "$UA" \
                "${BASE}/app.bsky.actor.getProfile?actor=${H}")
    if echo "$RESP" | jq -e '.handle' >/dev/null 2>&1; then
      echo "$RESP" | jq -r '
        "Handle:     \(.handle)",
        "DID:        \(.did)",
        "Display:    \(.displayName // "(none)")",
        "Created:    \(.createdAt // "?")",
        "Posts:      \(.postsCount // 0)",
        "Followers:  \(.followersCount // 0)",
        "Following:  \(.followsCount // 0)",
        "Verified:   \((.verification.verifiedStatus // "none"))",
        "",
        "Description:",
        (.description // "(none)")'
    else
      echo "$H → ikke fundet eller fejl"
      echo "$RESP" | jq . 2>/dev/null
    fi
    ;;

  search-posts)
    Q="${ARGS[*]:-}"
    [ -z "$Q" ] && { echo "Usage: $0 search-posts <query>" >&2; exit 1; }
    QENC=$(urlenc "$Q")
    RESP=$(curl -sSL --max-time 15 -A "$UA" \
                "${BASE}/app.bsky.feed.searchPosts?q=${QENC}&limit=${LIMIT}")
    HITS=$(echo "$RESP" | jq -r '.posts | length' 2>/dev/null)
    echo "=== Bluesky post-search: \"$Q\" → $HITS hits ==="
    echo "$RESP" | jq -r '.posts[]? |
      "── @\(.author.handle)  \(.indexedAt)
   display: \(.author.displayName // "(none)")
   text:    \((.record.text // "") | gsub("\n"; " ⏎ ") | .[0:200])
   link:    https://bsky.app/profile/\(.author.handle)/post/\(.uri | split("/") | last)"'
    ;;

  search-actors)
    Q="${ARGS[*]:-}"
    [ -z "$Q" ] && { echo "Usage: $0 search-actors <query>" >&2; exit 1; }
    QENC=$(urlenc "$Q")
    RESP=$(curl -sSL --max-time 15 -A "$UA" \
                "${BASE}/app.bsky.actor.searchActors?term=${QENC}&limit=${LIMIT}")
    HITS=$(echo "$RESP" | jq -r '.actors | length' 2>/dev/null)
    echo "=== Bluesky actor-search: \"$Q\" → $HITS hits ==="
    echo "$RESP" | jq -r '.actors[]? |
      "── @\(.handle)  followers=\(.followersCount // 0)  posts=\(.postsCount // 0)
   display: \(.displayName // "(none)")
   created: \(.createdAt // "?")
   desc:    \((.description // "") | .[0:160])"'
    ;;

  feed)
    H="${ARGS[0]:-}"
    [ -z "$H" ] && { echo "Usage: $0 feed <handle>" >&2; exit 1; }
    RESP=$(curl -sSL --max-time 15 -A "$UA" \
                "${BASE}/app.bsky.feed.getAuthorFeed?actor=${H}&limit=${LIMIT}")
    HITS=$(echo "$RESP" | jq -r '.feed | length' 2>/dev/null)
    echo "=== Bluesky feed @${H} → ${HITS} posts ==="
    echo "$RESP" | jq -r '.feed[]?.post |
      "── \(.indexedAt)
   text: \((.record.text // "") | gsub("\n"; " ⏎ ") | .[0:200])
   ❤ \(.likeCount // 0)  🔁 \(.repostCount // 0)  💬 \(.replyCount // 0)"'
    ;;

  check-handles)
    LIST="${ARGS[0]:-}"
    [ -z "$LIST" ] && { echo "Usage: $0 check-handles <h1,h2,...>" >&2; exit 1; }
    echo "Handle                                Status     Created          Posts  Followers"
    echo "$LIST" | tr ',' '\n' | while IFS= read -r H; do
      [ -z "$H" ] && continue
      RESP=$(curl -sSL --max-time 6 -A "$UA" \
                  "${BASE}/app.bsky.actor.getProfile?actor=${H}" 2>/dev/null)
      if echo "$RESP" | jq -e '.handle' >/dev/null 2>&1; then
        echo "$RESP" | jq -r "[\"$H\", \"EXISTS\", (.createdAt // \"?\")[:10], (.postsCount // 0), (.followersCount // 0)] | @tsv" \
          | awk -F'\t' '{printf "%-36s  %-9s  %-15s  %-5s  %s\n", $1, $2, $3, $4, $5}'
      else
        printf "%-36s  %-9s  %-15s  %-5s  %s\n" "$H" "FREE" "-" "-" "-"
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
echo "  - Bluesky public-api: ingen auth, ingen rate-cost." >&2
echo "  - 'created' < rolle-tiltrædelse for nøgleperson = reservation-pattern." >&2

#!/bin/bash
# socmint-reddit — passiv Reddit-SOCMINT via public JSON-endpoints.
# Reddit's old.reddit.com/.../*.json kræver ingen auth for read.
# Brug en distinkt User-Agent for at undgå rate-limit-fælder.
#
# Subkommandoer:
#   search <query>           Global Reddit-søgning på posts
#   subreddit <name>         Hot posts i et subreddit
#   user <name>              Sidste posts/kommentarer af en bruger
#   in-subreddit <sub> <q>   Søg query indenfor specifikt subreddit
#   mentions <brand>         Bredt mention-scan (search + r/Denmark fokus)
#
# Brug:
#   ./socmint-reddit.sh search "Nationalbanken"
#   ./socmint-reddit.sh in-subreddit Denmark "Nationalbanken"
#   ./socmint-reddit.sh user some_user
#   ./socmint-reddit.sh mentions "Danmarks Nationalbank"

set -uo pipefail

CMD="${1:-}"
shift || true

LIMIT=25
SORT="relevance"
TIME="all"
ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --limit) LIMIT="$2"; shift 2 ;;
    --sort)  SORT="$2"; shift 2 ;;
    --time)  TIME="$2"; shift 2 ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

if [ -z "$CMD" ]; then
  cat >&2 <<EOF
Usage: $0 <subcommand> [args] [--limit N] [--sort <relevance|hot|top|new>] [--time <hour|day|week|month|year|all>]
  search <query>           Global søgning
  subreddit <name>         Hot posts i subreddit
  user <name>              Bruger-aktivitet
  in-subreddit <sub> <q>   Søg i et subreddit
  mentions <brand>         Brand-mention-scan
EOF
  exit 1
fi

UA="osint-recon-recipe/1.0 (socmint-reddit; contact: ops@example.org)"
BASE="https://www.reddit.com"

urlenc() { jq -nr --arg v "$1" '$v | @uri'; }

fmt_results() {
  jq -r '.data.children[]?.data |
    "── r/\(.subreddit)  u/\(.author)  \(.created_utc | strftime("%Y-%m-%d %H:%M"))
   title:  \(.title // "" | gsub("\n"; " ") | .[0:120])
   score:  \(.score) • comments: \(.num_comments) • url: https://reddit.com\(.permalink)
   text:   \((.selftext // "") | gsub("\n"; " ⏎ ") | .[0:200])"'
}

fmt_user() {
  jq -r '.data.children[]?.data |
    if .kind == "t1" then
      "── COMMENT in r/\(.subreddit)  \(.created_utc | strftime("%Y-%m-%d %H:%M"))
   text:   \((.body // "") | gsub("\n"; " ⏎ ") | .[0:200])
   score:  \(.score)  link: https://reddit.com\(.permalink // "")"
    else
      "── POST    in r/\(.subreddit)  \(.created_utc | strftime("%Y-%m-%d %H:%M"))
   title:  \(.title // "")
   text:   \((.selftext // "") | gsub("\n"; " ⏎ ") | .[0:200])
   score:  \(.score)  url: https://reddit.com\(.permalink // "")"
    end'
}

case "$CMD" in
  search)
    Q="${ARGS[*]:-}"
    [ -z "$Q" ] && { echo "Usage: $0 search <query>" >&2; exit 1; }
    QENC=$(urlenc "$Q")
    URL="${BASE}/search.json?q=${QENC}&limit=${LIMIT}&sort=${SORT}&t=${TIME}&restrict_sr=off"
    echo "=== Reddit search: \"$Q\" (sort=${SORT}, time=${TIME}) ==="
    RESP=$(curl -sSL --max-time 15 -A "$UA" "$URL")
    HITS=$(echo "$RESP" | jq -r '.data.children | length' 2>/dev/null)
    echo "Hits: $HITS"
    echo "$RESP" | fmt_results
    ;;

  subreddit)
    S="${ARGS[0]:-}"
    [ -z "$S" ] && { echo "Usage: $0 subreddit <name>" >&2; exit 1; }
    URL="${BASE}/r/${S}/hot.json?limit=${LIMIT}"
    echo "=== r/${S} hot posts ==="
    curl -sSL --max-time 15 -A "$UA" "$URL" | fmt_results
    ;;

  user)
    U="${ARGS[0]:-}"
    [ -z "$U" ] && { echo "Usage: $0 user <name>" >&2; exit 1; }
    URL="${BASE}/user/${U}/overview.json?limit=${LIMIT}"
    echo "=== u/${U} aktivitet ==="
    RESP=$(curl -sSL --max-time 15 -A "$UA" "$URL")
    if echo "$RESP" | jq -e '.data' >/dev/null 2>&1; then
      ABOUT=$(curl -sSL --max-time 10 -A "$UA" "${BASE}/user/${U}/about.json")
      echo "$ABOUT" | jq -r '.data | "  Karma: \(.total_karma // 0)  (link=\(.link_karma // 0), comment=\(.comment_karma // 0))
  Created: \(.created_utc | strftime("%Y-%m-%d"))
  Verified: \(.has_verified_email // false)
  Description: \((.subreddit.public_description // "") | .[0:200])"'
      echo
      echo "$RESP" | fmt_user
    else
      echo "u/${U} ikke fundet eller skjult."
    fi
    ;;

  in-subreddit)
    S="${ARGS[0]:-}"
    Q="${ARGS[@]:1}"
    [ -z "$S" ] || [ -z "$Q" ] && { echo "Usage: $0 in-subreddit <subreddit> <query>" >&2; exit 1; }
    QENC=$(urlenc "$Q")
    URL="${BASE}/r/${S}/search.json?q=${QENC}&limit=${LIMIT}&restrict_sr=on&sort=${SORT}&t=${TIME}"
    echo "=== r/${S} search: \"$Q\" ==="
    RESP=$(curl -sSL --max-time 15 -A "$UA" "$URL")
    HITS=$(echo "$RESP" | jq -r '.data.children | length' 2>/dev/null)
    echo "Hits: $HITS"
    echo "$RESP" | fmt_results
    ;;

  mentions)
    B="${ARGS[*]:-}"
    [ -z "$B" ] && { echo "Usage: $0 mentions <brand>" >&2; exit 1; }
    BENC=$(urlenc "$B")
    echo "=== Brand-mention scan: \"$B\" ==="
    echo
    echo "[Global søgning]"
    curl -sSL --max-time 15 -A "$UA" \
      "${BASE}/search.json?q=${BENC}&limit=${LIMIT}&sort=new&restrict_sr=off&t=all" | fmt_results
    echo
    # Fokuser også på de mest relevante danske/finansielle subreddits
    for SUB in Denmark dkfinance europe Finanssen; do
      echo
      echo "[r/${SUB}]"
      curl -sSL --max-time 12 -A "$UA" \
        "${BASE}/r/${SUB}/search.json?q=${BENC}&restrict_sr=on&limit=10&sort=new&t=all" | fmt_results
    done
    ;;

  *)
    echo "Unknown subcommand: $CMD" >&2
    exit 1
    ;;
esac

echo "" >&2
echo "Bemærk:" >&2
echo "  - Reddit kræver ikke auth for read, men har strenge rate-limits." >&2
echo "  - Brug --sort new --time week for løbende monitoring-cadens." >&2

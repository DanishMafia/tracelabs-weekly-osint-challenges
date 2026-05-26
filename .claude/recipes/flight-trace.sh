#!/bin/bash
# Spor et fly's landings/takeoffs på en specifik dato.
#
# Brug:
#   ./flight-trace.sh N628TS 2025-09-19
#   ./flight-trace.sh N628TS 2025-09-19 elonjet
#
# Default tracker-konto er @elonjet@mastodon.social (Elon Musk's jets).
# For andre fly: lav en lignende tracker-konto-lookup, eller udvid scriptet.
#
# Metode:
#  1. Slå Mastodon-konto-ID op
#  2. Paginér statuses bagud indtil måldatoen er ramt
#  3. Filtrér på halenummer + dato
#
# Begrænsninger: kun fly der har en åben tracker på Mastodon. For andre,
# brug FlightAware/Plane Finder manuelt.

set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <tail-number> <YYYY-MM-DD> [tracker-account=elonjet]" >&2
  exit 1
fi

TAIL="$1"
DATE="$2"
ACCT="${3:-elonjet}"
INSTANCE="mastodon.social"

# Slå konto-ID op
ID=$(curl -sH 'User-Agent: tracelabs-osint (educational)' \
  "https://$INSTANCE/api/v1/accounts/lookup?acct=$ACCT" \
  | jq -r '.id // empty')

if [ -z "$ID" ]; then
  echo "Error: konto @$ACCT@$INSTANCE ikke fundet" >&2
  exit 1
fi

echo "Sporer $TAIL på $DATE via @$ACCT@$INSTANCE (id=$ID)..."

MAX_ID=""
FOUND=0
for PAGE in $(seq 1 50); do
  URL="https://$INSTANCE/api/v1/accounts/$ID/statuses?limit=40&exclude_replies=true&exclude_reblogs=true"
  [ -n "$MAX_ID" ] && URL="${URL}&max_id=${MAX_ID}"
  curl -sH 'User-Agent: tracelabs-osint (educational)' "$URL" -o /tmp/flight_page.json
  COUNT=$(jq 'length' /tmp/flight_page.json)
  [ "$COUNT" -eq 0 ] && break

  OLDEST=$(jq -r '.[-1].created_at[0:10]' /tmp/flight_page.json)
  MAX_ID=$(jq -r '.[-1].id' /tmp/flight_page.json)

  # Find statuses fra måldatoen
  HITS=$(jq -r --arg d "$DATE" '
    .[] | select(.created_at | startswith($d)) |
    "\(.created_at[0:19])  \(.content | gsub("<[^>]+>"; "") | gsub("\n"; " "))"
  ' /tmp/flight_page.json)

  if [ -n "$HITS" ]; then
    echo
    echo "=== $TAIL aktivitet på $DATE ==="
    echo "$HITS"
    FOUND=1
  fi

  # Stop hvis vi er gået forbi datoen
  if [[ "$OLDEST" < "$DATE" ]]; then
    break
  fi
  sleep 0.3
done

if [ "$FOUND" -eq 0 ]; then
  echo "Ingen aktivitet fundet for $TAIL på $DATE" >&2
  exit 2
fi

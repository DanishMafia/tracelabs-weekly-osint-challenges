#!/bin/bash
# Wayback Machine — bevar en URL eller tjek eksisterende snapshots.
# Bruger Internet Archive's offentlige Save Page Now + Availability API.
# Ingen autentificering.
#
# Brug:
#   ./archive-url.sh check  https://example.com/page
#   ./archive-url.sh save   https://example.com/page
#   ./archive-url.sh list   https://example.com/page    # alle snapshots

set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage:" >&2
  echo "  $0 check <url>   # nyeste snapshot (eller intet)" >&2
  echo "  $0 save  <url>   # send URL til Save Page Now (Wayback)" >&2
  echo "  $0 list  <url>   # CDX-liste over alle snapshots" >&2
  exit 1
fi

CMD="$1"
URL="$2"
UA="tracelabs-osint-archive/1.0"

case "$CMD" in
  check)
    echo "=== Wayback — check ==="
    echo "URL: $URL"
    echo
    RESP=$(curl -fsSL --max-time 15 -A "$UA" \
      "https://archive.org/wayback/available?url=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$URL")" \
      2>/dev/null || echo '{}')

    AVAIL=$(echo "$RESP" | jq -r '.archived_snapshots.closest.available // false')
    if [ "$AVAIL" = "true" ]; then
      echo "Snapshot fundet:"
      echo "  Timestamp: $(echo "$RESP" | jq -r '.archived_snapshots.closest.timestamp')"
      echo "  Status:    $(echo "$RESP" | jq -r '.archived_snapshots.closest.status')"
      echo "  URL:       $(echo "$RESP" | jq -r '.archived_snapshots.closest.url')"
    else
      echo "Intet snapshot. Kør '$0 save $URL' for at bevare nu."
    fi
    ;;

  save)
    echo "=== Wayback — Save Page Now ==="
    echo "URL: $URL"
    echo
    SAVE_URL="https://web.archive.org/save/$URL"
    echo "Sender til SPN... (kan tage 10-30s)"
    HEADERS=$(curl -fsSL --max-time 60 -A "$UA" -D /tmp/spn-headers-$$ \
      -o /dev/null "$SAVE_URL" 2>&1 || true)
    LOCATION=$(grep -i '^content-location:' /tmp/spn-headers-$$ 2>/dev/null | awk '{print $2}' | tr -d '\r' || true)
    rm -f /tmp/spn-headers-$$
    if [ -n "$LOCATION" ]; then
      echo "Snapshot oprettet:"
      echo "  https://web.archive.org${LOCATION}"
    else
      echo "Snapshot accepteret af SPN. Tjek om få sekunder med:"
      echo "  $0 check $URL"
    fi
    ;;

  list)
    echo "=== Wayback CDX — alle snapshots ==="
    echo "URL: $URL"
    echo
    CDX=$(curl -fsSL --max-time 30 -A "$UA" \
      "http://web.archive.org/cdx/search/cdx?url=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$URL")&output=json&limit=50" \
      2>/dev/null || echo '[]')

    COUNT=$(echo "$CDX" | jq 'length - 1' 2>/dev/null || echo 0)
    [ "$COUNT" -lt 0 ] && COUNT=0
    echo "$COUNT snapshot(s) fundet (max 50):"
    echo "$CDX" | jq -r '.[1:] | .[] | "  \(.[1])  status=\(.[4])  https://web.archive.org/web/\(.[1])/\(.[2])"' 2>/dev/null
    ;;

  *)
    echo "Error: ukendt kommando '$CMD'. Brug: check | save | list" >&2
    exit 1
    ;;
esac

echo
echo "Bemærk: Brug 'save' før du citerer en kilde der kunne ændre sig"
echo "(sociale medier, nyhedsartikler, statussider osv.)."

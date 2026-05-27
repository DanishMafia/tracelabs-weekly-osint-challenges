#!/bin/bash
# urlhaus-check — query abuse.ch URLhaus for malware/phishing-URLs
# der nævner et brand eller domæne. Gratis, ingen auth krævet.
#
# Brug:
#   ./urlhaus-check.sh host nationalbanken.dk   # match på host
#   ./urlhaus-check.sh url <full-url>           # full URL lookup
#   ./urlhaus-check.sh tag nationalbanken       # search by tag/keyword

set -uo pipefail

CMD="${1:-}"
QUERY="${2:-}"

if [ -z "$CMD" ] || [ -z "$QUERY" ]; then
  echo "Usage: $0 <host|url|tag> <value>" >&2
  echo "  host <domain>   Match URLs hosted at this domain" >&2
  echo "  url <full-url>  Lookup specific URL" >&2
  echo "  tag <keyword>   Search by tag" >&2
  exit 1
fi

UA="osint-recon-recipe/1.0 (urlhaus-check)"
BASE="https://urlhaus-api.abuse.ch/v1"

case "$CMD" in
  host)
    BODY=$(curl -sSL --max-time 20 -A "$UA" \
              --data "host=${QUERY}" \
              "${BASE}/host/" 2>/dev/null)
    echo "=== URLhaus host: $QUERY ===" >&2
    STATUS=$(echo "$BODY" | jq -r '.query_status // "unknown"')
    case "$STATUS" in
      ok)
        echo "URL count:    $(echo "$BODY" | jq -r '.url_count // 0')"
        echo "First seen:   $(echo "$BODY" | jq -r '.firstseen // "n/a"')"
        echo "Blacklists:   $(echo "$BODY" | jq -r '.blacklists | to_entries[]? | "\(.key)=\(.value)"' | tr '\n' ' ')"
        echo
        echo "[URLs]"
        echo "$BODY" | jq -r '.urls[]? |
          "── \(.url)
   status:     \(.url_status // "?")
   threat:     \(.threat // "?")
   tags:       \(.tags // [] | join(", "))
   first seen: \(.date_added // "?")
   reporter:   \(.reporter // "?")"' | head -60
        ;;
      no_results)
        echo "Ingen URLs fundet for host $QUERY."
        ;;
      *)
        echo "URLhaus status: $STATUS" >&2
        echo "$BODY" | jq . >&2
        exit 1
        ;;
    esac
    ;;

  url)
    BODY=$(curl -sSL --max-time 20 -A "$UA" \
              --data "url=${QUERY}" \
              "${BASE}/url/" 2>/dev/null)
    echo "=== URLhaus URL: $QUERY ===" >&2
    echo "$BODY" | jq .
    ;;

  tag)
    BODY=$(curl -sSL --max-time 20 -A "$UA" \
              --data "tag=${QUERY}" \
              "${BASE}/tag/" 2>/dev/null)
    echo "=== URLhaus tag: $QUERY ===" >&2
    STATUS=$(echo "$BODY" | jq -r '.query_status // "unknown"')
    if [ "$STATUS" = "ok" ]; then
      echo "URL count: $(echo "$BODY" | jq -r '.url_count // 0')"
      echo "$BODY" | jq -r '.urls[]? | "── \(.url)  [\(.threat // "?")  \(.date_added // "?")]"' | head -40
    else
      echo "Status: $STATUS"
    fi
    ;;

  *)
    echo "Unknown subcommand: $CMD" >&2
    exit 1
    ;;
esac

echo "" >&2
echo "Bemærk:" >&2
echo "  - URLhaus drives af abuse.ch — pålidelig feed, men ikke udtømmende." >&2
echo "  - 0 results = ikke i URLhaus; betyder ikke nødvendigvis 'rent'." >&2
echo "  - Krydsreferer med urlscan og PhishTank for bedre coverage." >&2

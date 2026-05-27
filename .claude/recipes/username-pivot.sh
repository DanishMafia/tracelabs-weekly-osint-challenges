#!/bin/bash
# Username pivot — søg et alias/handle på tværs af 600+ sider via
# WhatsMyName-projektets offentlige JSON-database. Ingen API-nøgler.
#
# Brug:
#   ./username-pivot.sh "DanishMafia"
#   ./username-pivot.sh "DanishMafia" --category social
#   ./username-pivot.sh "DanishMafia" --limit 50
#   ./username-pivot.sh "DanishMafia" --concurrency 10
#
# Default limit er 100 sites for at undgå at hamre på alle 600+ sider
# (mange vil rate-limite eller blokere). Sæt --limit 0 for at køre alle.
#
# Output (stdout): én linje pr. site — STATUS  NAVN  URL.
#   HIT          = e_string fundet i body med matching status. Verificér.
#   string-miss  = status matched men e_string manglede (rate-limit / layout-ændring).
#   no           = ingen indikation af konto.
#   timeout      = DNS/timeout/netværksfejl.

set -uo pipefail

USERNAME=""
CATEGORY=""
LIMIT=100
CONCURRENCY=10

while [ $# -gt 0 ]; do
  case "$1" in
    --category)    CATEGORY="$2"; shift 2 ;;
    --limit)       LIMIT="$2"; shift 2 ;;
    --concurrency) CONCURRENCY="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 <username> [--category <cat>] [--limit N] [--concurrency N]"
      echo "  --limit 0  scanner ALLE sites (~600). Default 100."
      exit 0 ;;
    -*) echo "Unknown flag: $1" >&2; exit 1 ;;
    *)  USERNAME="$1"; shift ;;
  esac
done

if [ -z "$USERNAME" ]; then
  echo "Usage: $0 <username> [--category <cat>] [--limit N] [--concurrency N]" >&2
  exit 1
fi

WMN_URL="https://raw.githubusercontent.com/WebBreacher/WhatsMyName/main/wmn-data.json"
CACHE="/tmp/wmn-data.json"

if [ ! -f "$CACHE" ] || [ -n "$(find "$CACHE" -mtime +7 2>/dev/null)" ]; then
  echo "Henter WhatsMyName-database..." >&2
  curl -fsSL --max-time 30 "$WMN_URL" -o "$CACHE" || {
    echo "Error: kunne ikke hente $WMN_URL" >&2
    exit 1
  }
fi

TOTAL=$(jq '.sites | length' "$CACHE")
echo "=== Username-pivot: $USERNAME ===" >&2
echo "WhatsMyName: $TOTAL sites i database" >&2
[ -n "$CATEGORY" ] && echo "Filter: kategori=$CATEGORY" >&2
[ "$LIMIT" -gt 0 ] && echo "Limit: $LIMIT" >&2
echo "Concurrency: $CONCURRENCY" >&2
echo >&2

FILTER='.sites[]'
if [ -n "$CATEGORY" ]; then
  FILTER=".sites[] | select(.cat==\"$CATEGORY\")"
fi
if [ "$LIMIT" -gt 0 ]; then
  FILTER="[$FILTER] | .[0:$LIMIT] | .[]"
fi

check_site() {
  local SITE_JSON="$1"
  local NAME URI_CHECK E_CODE E_STRING URL BODY RESP STATUS

  NAME=$(echo "$SITE_JSON" | jq -r '.name')
  URI_CHECK=$(echo "$SITE_JSON" | jq -r '.uri_check')
  E_CODE=$(echo "$SITE_JSON" | jq -r '.e_code')
  E_STRING=$(echo "$SITE_JSON" | jq -r '.e_string')
  URL="${URI_CHECK//\{account\}/$USERNAME}"

  BODY=$(mktemp)
  RESP=$(curl -sSL --max-time 8 -o "$BODY" -w '%{http_code}' \
              -A 'Mozilla/5.0 (osint-pivot)' "$URL" 2>/dev/null || echo "000")

  if [ "$RESP" = "$E_CODE" ] && grep -qF -- "$E_STRING" "$BODY" 2>/dev/null; then
    STATUS="HIT"
  elif [ "$RESP" = "000" ]; then
    STATUS="timeout"
  elif [ "$RESP" = "$E_CODE" ]; then
    STATUS="string-miss"
  else
    STATUS="no"
  fi

  rm -f "$BODY"
  printf '%-12s  %-25s  %s\n' "$STATUS" "$NAME" "$URL"
}

export -f check_site
export USERNAME

jq -c "$FILTER" "$CACHE" | while IFS= read -r SITE_JSON; do
  # Bash-niveau job-throttle — ingen xargs, ingen quoting-injection.
  while [ "$(jobs -rp | wc -l)" -ge "$CONCURRENCY" ]; do
    wait -n 2>/dev/null || sleep 0.1
  done
  check_site "$SITE_JSON" &
done
wait

echo >&2
echo "Bemærk:" >&2
echo "  - HIT = bekræftet konto-signal. Verificér visuelt før konklusion." >&2
echo "  - string-miss = status matched men e_string manglede — kan være" >&2
echo "    rate-limit, layout-ændring eller falsk positiv. Tjek manuelt." >&2
echo "  - Default scanner kun de første 100 sites. Brug --limit 0 for alle." >&2
echo "  - Pivotér derefter til osint-username-search skill for dybere graving." >&2

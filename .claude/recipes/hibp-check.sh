#!/bin/bash
# HIBP-check — slår en e-mail eller domain op mod Have I Been Pwned.
#
# Tre modes:
#   email   <addr>     Kræver HIBP_API_KEY (betalt). Returnerer breach-liste.
#   domain  <domain>   Public endpoint. Lister breaches der inkluderede domain.
#   pastes  <addr>     Kræver HIBP_API_KEY. Returnerer paste-hits.
#
# Brug:
#   ./hibp-check.sh domain example.com
#   export HIBP_API_KEY=...
#   ./hibp-check.sh email user@example.com
#   ./hibp-check.sh pastes user@example.com
#
# HIBP API-key kræver et "Pwned" abonnement: https://haveibeenpwned.com/API/Key

set -uo pipefail

MODE="${1:-}"
INPUT="${2:-}"

if [ -z "$MODE" ] || [ -z "$INPUT" ]; then
  echo "Usage: $0 <email|domain|pastes> <value>" >&2
  exit 1
fi

UA="redteam-recon-recipe/1.0 (HIBP-check)"

case "$MODE" in
  domain)
    # Public endpoint: breaches der inkluderede dette domain
    URL="https://haveibeenpwned.com/api/v3/breaches?domain=${INPUT}"
    echo "=== HIBP domain-search: $INPUT ===" >&2
    RESP=$(curl -fsSL --max-time 20 -A "$UA" "$URL" 2>/dev/null)
    if [ -z "$RESP" ] || [ "$RESP" = "[]" ]; then
      echo "Ingen kendte breaches med dette domain."
      exit 0
    fi
    echo "$RESP" | jq -r '.[] | "- \(.Name) (\(.BreachDate))\n  Pwned accounts: \(.PwnCount)\n  Data: \(.DataClasses | join(", "))\n  \(.Description | sub("<[^>]+>"; ""; "g") | .[0:200])...\n"'
    ;;

  email|pastes)
    if [ -z "${HIBP_API_KEY:-}" ]; then
      echo "Error: HIBP_API_KEY env var skal sættes." >&2
      echo "Køb en key: https://haveibeenpwned.com/API/Key" >&2
      exit 1
    fi
    ENCODED=$(printf '%s' "$INPUT" | jq -sRr @uri)
    if [ "$MODE" = "email" ]; then
      URL="https://haveibeenpwned.com/api/v3/breachedaccount/${ENCODED}?truncateResponse=false"
      LABEL="breaches"
    else
      URL="https://haveibeenpwned.com/api/v3/pasteaccount/${ENCODED}"
      LABEL="pastes"
    fi
    echo "=== HIBP $LABEL: $INPUT ===" >&2
    RESP=$(curl -sSL --max-time 20 \
                -A "$UA" \
                -H "hibp-api-key: $HIBP_API_KEY" \
                -w '\n%{http_code}' "$URL" 2>/dev/null)
    CODE=$(echo "$RESP" | tail -n1)
    BODY=$(echo "$RESP" | sed '$d')
    case "$CODE" in
      200)
        if [ "$MODE" = "email" ]; then
          echo "$BODY" | jq -r '.[] | "- \(.Name) (\(.BreachDate)) – \(.DataClasses | join(", "))"'
        else
          echo "$BODY" | jq -r '.[] | "- [\(.Source)] \(.Id) (\(.Date // "ukendt"))"'
        fi
        ;;
      404) echo "Ingen $LABEL fundet for $INPUT." ;;
      401|403) echo "Auth-fejl (401/403). Tjek HIBP_API_KEY." >&2; exit 1 ;;
      429) echo "Rate-limited. Vent og prøv igen." >&2; exit 1 ;;
      *)   echo "Uventet HTTP-status: $CODE" >&2; echo "$BODY" >&2; exit 1 ;;
    esac
    ;;

  *)
    echo "Unknown mode: $MODE (skal være email|domain|pastes)" >&2
    exit 1
    ;;
esac

echo "" >&2
echo "Bemærk:" >&2
echo "  - Brug af breach-data kræver kontraktlig dækning i red-team-engagement." >&2
echo "  - Slå IKKE passwords op via gråzone-databaser uden eksplicit autorisation." >&2

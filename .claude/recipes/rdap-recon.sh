#!/bin/bash
# rdap-recon — domæne-information via RDAP (HTTPS-baseret WHOIS-erstatning).
# Virker hvor port-43 WHOIS er blokeret. ICANN driver RDAP-bootstrap der
# router lookups til rette TLD-registrar. Mange .com/.net/.org/.eu/.io
# fungerer; .dk har desværre ingen offentligt RDAP-endpoint endnu.
#
# Subkommandoer:
#   domain <name>            Domæne-detaljer (registrar, dates, NS, status)
#   bulk <name1,name2,...>   Batch-lookup på flere domæner
#   ip <ip>                  RDAP for en IP (RIR-info)
#   registrar <name>         Identificer hvilken registrar et domæne bruger
#
# Brug:
#   ./rdap-recon.sh domain nationalbanken.com
#   ./rdap-recon.sh bulk nationalbanken.com,nationalbanken.org,nationalbanken.xyz
#   ./rdap-recon.sh ip 20.105.232.45

set -uo pipefail

CMD="${1:-}"
shift || true

ARGS=()
while [ $# -gt 0 ]; do
  ARGS+=("$1"); shift
done

if [ -z "$CMD" ]; then
  cat >&2 <<EOF
Usage: $0 <subcommand> [args]
  domain <name>            Detaljer for ét domæne
  bulk <n1,n2,...>         Batch-lookup
  ip <ip>                  IP RIR-info
  registrar <name>         Hvilken registrar bruges?
EOF
  exit 1
fi

UA="osint-recon-recipe/1.0 (rdap-recon)"

# Bruger rdap.org som universal proxy (ICANN-rutet)
RDAP_BASE="https://rdap.org"

rdap_get() {
  local PATH_="$1"
  curl -sSL --max-time 15 -A "$UA" -H "Accept: application/rdap+json" \
    "${RDAP_BASE}${PATH_}" 2>/dev/null
}

format_domain() {
  local BODY="$1"
  local NAME="$2"
  if echo "$BODY" | jq -e '.errorCode' >/dev/null 2>&1; then
    local CODE=$(echo "$BODY" | jq -r '.errorCode')
    local TITLE=$(echo "$BODY" | jq -r '.title // "?"')
    printf "  %-30s  ERROR %s  %s\n" "$NAME" "$CODE" "$TITLE"
    return 1
  fi
  echo "$BODY" | jq -r '
    "Name:        \(.ldhName // .unicodeName // "?")",
    "Handle:      \(.handle // "?")",
    "Status:      \((.status // []) | join(", "))",
    "Created:    \((.events // []) | map(select(.eventAction == "registration")) | .[0].eventDate // "?")",
    "Updated:    \((.events // []) | map(select(.eventAction == "last changed")) | .[0].eventDate // "?")",
    "Expires:    \((.events // []) | map(select(.eventAction == "expiration")) | .[0].eventDate // "?")",
    "Registrar:   \((.entities // []) | map(select((.roles // []) | index("registrar"))) | .[0] | (.vcardArray // [.,[]])[1] | map(select(.[0] == "fn")) | .[0][3] // "?")",
    "Abuse-email: \((.entities // []) | .. | objects | select((.roles // []) | index("abuse")?) | (.vcardArray // [.,[]])[1]? | map(select(.[0] == "email"))? | .[0][3]? // "n/a") // "n/a"",
    "Nameservers:",
    ((.nameservers // [])[] | "  - \(.ldhName // "?")")'
}

case "$CMD" in
  domain)
    N="${ARGS[0]:-}"
    [ -z "$N" ] && { echo "Usage: $0 domain <name>" >&2; exit 1; }
    echo "=== RDAP: $N ==="
    BODY=$(rdap_get "/domain/${N}")
    if [ -z "$BODY" ]; then
      echo "  Ingen RDAP-respons. TLD understøtter måske ikke RDAP (fx .dk)."
      exit 1
    fi
    format_domain "$BODY" "$N"
    ;;

  bulk)
    LIST="${ARGS[0]:-}"
    [ -z "$LIST" ] && { echo "Usage: $0 bulk <n1,n2,...>" >&2; exit 1; }
    printf "%-30s  %-12s  %-12s  %-30s  %s\n" "Domain" "Created" "Expires" "Registrar" "Status"
    echo "$LIST" | tr ',' '\n' | while IFS= read -r N; do
      [ -z "$N" ] && continue
      BODY=$(rdap_get "/domain/${N}")
      if echo "$BODY" | jq -e '.errorCode' >/dev/null 2>&1; then
        printf "%-30s  %s\n" "$N" "(no RDAP)"
        continue
      fi
      CREATED=$(echo "$BODY" | jq -r '(.events // []) | map(select(.eventAction == "registration")) | .[0].eventDate // "?" | .[:10]')
      EXPIRES=$(echo "$BODY" | jq -r '(.events // []) | map(select(.eventAction == "expiration")) | .[0].eventDate // "?" | .[:10]')
      REG=$(echo "$BODY" | jq -r '(.entities // []) | map(select((.roles // []) | index("registrar"))) | .[0] | (.vcardArray // [.,[]])[1] | map(select(.[0] == "fn")) | .[0][3] // "?"' | cut -c1-30)
      STATUS=$(echo "$BODY" | jq -r '(.status // []) | join(",")' | cut -c1-30)
      printf "%-30s  %-12s  %-12s  %-30s  %s\n" "$N" "$CREATED" "$EXPIRES" "$REG" "$STATUS"
    done
    ;;

  ip)
    IP="${ARGS[0]:-}"
    [ -z "$IP" ] && { echo "Usage: $0 ip <ip>" >&2; exit 1; }
    echo "=== RDAP IP: $IP ==="
    BODY=$(rdap_get "/ip/${IP}")
    echo "$BODY" | jq -r '
      "Handle:    \(.handle // "?")",
      "Name:      \(.name // "?")",
      "Range:     \(.startAddress // "?") - \(.endAddress // "?")",
      "Country:   \(.country // "?")",
      "Type:      \(.type // "?")",
      "Status:    \((.status // []) | join(", "))",
      "Registered: \((.events // []) | map(select(.eventAction == "registration")) | .[0].eventDate // "?")",
      "Updated:    \((.events // []) | map(select(.eventAction == "last changed")) | .[0].eventDate // "?")"'
    ;;

  registrar)
    N="${ARGS[0]:-}"
    [ -z "$N" ] && { echo "Usage: $0 registrar <name>" >&2; exit 1; }
    BODY=$(rdap_get "/domain/${N}")
    REG=$(echo "$BODY" | jq -r '(.entities // []) | map(select((.roles // []) | index("registrar"))) | .[0] | (.vcardArray // [.,[]])[1] | map(select(.[0] == "fn")) | .[0][3] // "?"')
    ABUSE=$(echo "$BODY" | jq -r '
      (.entities // []) | .. | objects
      | select((.roles // []) | index("abuse")?)
      | (.vcardArray // [.,[]])[1]?
      | map(select(.[0] == "email"))?
      | .[0][3]? // ""' 2>/dev/null | head -1)
    echo "Domain:    $N"
    echo "Registrar: $REG"
    echo "Abuse:     ${ABUSE:-(none in RDAP)}"
    ;;

  *)
    echo "Unknown subcommand: $CMD" >&2
    exit 1
    ;;
esac

echo "" >&2
echo "Bemærk:" >&2
echo "  - RDAP er ICANN's HTTPS-erstatning for whois. Virker over standard 443." >&2
echo "  - Ikke alle TLDs har RDAP (.dk pt. ikke understøttet — brug DK Hostmaster manuelt)." >&2
echo "  - Abuse-email er kritisk ved take-down. Hvis tom: tjek registrar-side." >&2

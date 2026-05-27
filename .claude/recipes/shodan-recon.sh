#!/bin/bash
# Shodan recon — wrapper omkring Shodan API til passive infrastructure-opslag.
#
# Subkommandoer:
#   host <ip>                  Detaljer for en host (porte, bannere, vulns, certs)
#   search <query>             Shodan search (koster query-credit)
#   count <query>              Tæller resultater uden at bruge credit
#   dns <hostname>             Resolve hostname → IP (DNS-resolve)
#   reverse <ip>               Reverse DNS (IP → hostnames) ifølge Shodan
#   info                       Account-info + tilbageværende credits
#   facet <query> <facet>      Aggregér en query (fx top porte, top org, top country)
#
# API-key læses fra $SHODAN_API_KEY (eller flag --key).
#
# Brug:
#   export SHODAN_API_KEY=...
#   ./shodan-recon.sh host 8.8.8.8
#   ./shodan-recon.sh search 'apache country:DK port:80'
#   ./shodan-recon.sh facet 'org:"Example Inc"' country
#   ./shodan-recon.sh info
#
# Etisk note: Shodan-opslag er passive (data er allerede indsamlet af
# Shodan-platformen). Brug IKKE resultater til at angribe systemer uden
# skriftlig autorisation.

set -uo pipefail

CMD="${1:-}"
shift || true

KEY="${SHODAN_API_KEY:-}"
PAGE=1
LIMIT_FACET=10
QUERY_FACET=""

# Parse flags efter den primære subkommando
ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --key)   KEY="$2"; shift 2 ;;
    --page)  PAGE="$2"; shift 2 ;;
    --limit) LIMIT_FACET="$2"; shift 2 ;;
    --) shift; while [ $# -gt 0 ]; do ARGS+=("$1"); shift; done ;;
    *)  ARGS+=("$1"); shift ;;
  esac
done

if [ -z "$KEY" ] && [ "$CMD" != "" ]; then
  echo "Error: \$SHODAN_API_KEY ikke sat (eller brug --key)." >&2
  echo "Hent en: https://account.shodan.io/" >&2
  exit 1
fi

if [ -z "$CMD" ]; then
  cat >&2 <<EOF
Usage: $0 <subcommand> [args]
  host <ip>                 Host-detaljer
  search <query>            Shodan search
  count <query>             Count uden credit-træk
  dns <hostname>            Resolve → IP
  reverse <ip>              Reverse DNS
  info                      Account-info / credits
  facet <query> <facet>     Aggregér (facet = country, org, port, product, asn, ...)

Flags:
  --key <key>     API-key (default: \$SHODAN_API_KEY)
  --page <n>      Page-number for search (default 1)
  --limit <n>     Antal facet-resultater (default 10)
EOF
  exit 1
fi

BASE="https://api.shodan.io"
UA="osint-recon-recipe/1.0 (shodan-recon)"

# Lille hjælper der url-encoder en string
urlenc() {
  jq -nr --arg v "$1" '$v | @uri'
}

http_get() {
  local URL="$1"
  local RESP
  RESP=$(curl -sSL --max-time 30 -A "$UA" -w '\n%{http_code}' "$URL" 2>/dev/null)
  local CODE
  CODE=$(echo "$RESP" | tail -n1)
  local BODY
  BODY=$(echo "$RESP" | sed '$d')
  case "$CODE" in
    200) printf '%s' "$BODY" ;;
    401|403) echo "Auth-fejl ($CODE). Tjek SHODAN_API_KEY." >&2; return 1 ;;
    404) echo "Ikke fundet (404)." >&2; return 1 ;;
    429) echo "Rate-limited (429). Vent og prøv igen." >&2; return 1 ;;
    402) echo "Ikke tilstrækkelig credit (402). Tjek 'shodan-recon.sh info'." >&2; return 1 ;;
    *) echo "Uventet HTTP $CODE." >&2; echo "$BODY" >&2; return 1 ;;
  esac
}

case "$CMD" in
  host)
    IP="${ARGS[0]:-}"
    if [ -z "$IP" ]; then echo "Usage: $0 host <ip>" >&2; exit 1; fi
    if ! echo "$IP" | grep -qE '^([0-9]{1,3}\.){3}[0-9]{1,3}$|^[0-9a-fA-F:]+$'; then
      echo "Error: '$IP' ligner ikke en IP." >&2; exit 1
    fi
    echo "=== Shodan host: $IP ===" >&2
    BODY=$(http_get "${BASE}/shodan/host/${IP}?key=${KEY}") || exit 1
    echo "$BODY" | jq -r '
      "IP:           \(.ip_str)",
      "Org:          \(.org // "n/a")",
      "ISP:          \(.isp // "n/a")",
      "ASN:          \(.asn // "n/a")",
      "Country:      \(.country_name // "n/a") (\(.country_code // "n/a"))",
      "City:         \(.city // "n/a")",
      "OS:           \(.os // "n/a")",
      "Hostnames:    \((.hostnames // []) | join(", "))",
      "Domains:      \((.domains // []) | join(", "))",
      "Last update:  \(.last_update // "n/a")",
      "Ports:        \((.ports // []) | map(tostring) | join(", "))",
      "",
      "Vulns:",
      ((.vulns // {}) | to_entries | if length == 0 then "  (ingen)" else .[] | "  - \(.key)  CVSS \(.value.cvss // "?")  \(.value.summary // "" | .[0:120])" end),
      "",
      "Services:"
    '
    echo "$BODY" | jq -r '.data[] |
      "  ── port \(.port)/\(.transport // "tcp")  [\(.product // .module // "?")  \(.version // "")]",
      "     last seen: \(.timestamp // "n/a")",
      "     banner:    \((.data // "" | .[0:200] | gsub("\n"; " ⏎ ")))"'
    ;;

  search)
    Q="${ARGS[*]:-}"
    if [ -z "$Q" ]; then echo "Usage: $0 search <query>" >&2; exit 1; fi
    QENC=$(urlenc "$Q")
    echo "=== Shodan search: $Q (page $PAGE) ===" >&2
    BODY=$(http_get "${BASE}/shodan/host/search?key=${KEY}&query=${QENC}&page=${PAGE}") || exit 1
    TOTAL=$(echo "$BODY" | jq -r '.total // 0')
    echo "Total matches: $TOTAL" >&2
    echo
    echo "$BODY" | jq -r '.matches[]? |
      "── \(.ip_str):\(.port)  [\(.org // "?") / \(.location.country_code // "?")]
   product: \(.product // "?")  version: \(.version // "")
   hostnames: \((.hostnames // []) | join(", "))
   banner:    \((.data // "" | .[0:160] | gsub("\n"; " ⏎ ")))
"'
    ;;

  count)
    Q="${ARGS[*]:-}"
    if [ -z "$Q" ]; then echo "Usage: $0 count <query>" >&2; exit 1; fi
    QENC=$(urlenc "$Q")
    echo "=== Shodan count: $Q ===" >&2
    BODY=$(http_get "${BASE}/shodan/host/count?key=${KEY}&query=${QENC}") || exit 1
    echo "$BODY" | jq -r '"Total: \(.total)"'
    ;;

  dns)
    H="${ARGS[0]:-}"
    if [ -z "$H" ]; then echo "Usage: $0 dns <hostname>[,<hostname>...]" >&2; exit 1; fi
    HENC=$(urlenc "$H")
    echo "=== Shodan DNS resolve: $H ===" >&2
    BODY=$(http_get "${BASE}/dns/resolve?hostnames=${HENC}&key=${KEY}") || exit 1
    echo "$BODY" | jq -r 'to_entries[] | "  \(.key) → \(.value)"'
    ;;

  reverse)
    IP="${ARGS[0]:-}"
    if [ -z "$IP" ]; then echo "Usage: $0 reverse <ip>[,<ip>...]" >&2; exit 1; fi
    IPENC=$(urlenc "$IP")
    echo "=== Shodan reverse DNS: $IP ===" >&2
    BODY=$(http_get "${BASE}/dns/reverse?ips=${IPENC}&key=${KEY}") || exit 1
    echo "$BODY" | jq -r 'to_entries[] | "  \(.key):\n    " + ((.value // []) | join("\n    "))'
    ;;

  info)
    echo "=== Shodan account info ===" >&2
    BODY=$(http_get "${BASE}/api-info?key=${KEY}") || exit 1
    echo "$BODY" | jq -r '
      "Plan:              \(.plan // "n/a")",
      "Query credits:     \(.query_credits // 0)",
      "Scan credits:      \(.scan_credits // 0)",
      "Monitored IPs:     \(.monitored_ips // "n/a")",
      "Unlocked left:     \(.unlocked_left // "n/a")",
      "HTTPS enabled:     \(.https // false)",
      "Telnet enabled:    \(.telnet // false)"'
    ;;

  facet)
    Q="${ARGS[0]:-}"
    F="${ARGS[1]:-}"
    if [ -z "$Q" ] || [ -z "$F" ]; then
      echo "Usage: $0 facet <query> <facet>" >&2
      echo "Common facets: country, org, port, product, asn, os, city, version" >&2
      exit 1
    fi
    QENC=$(urlenc "$Q")
    FSPEC="${F}:${LIMIT_FACET}"
    FENC=$(urlenc "$FSPEC")
    echo "=== Shodan facet: $Q  facet=$F  top $LIMIT_FACET ===" >&2
    BODY=$(http_get "${BASE}/shodan/host/count?key=${KEY}&query=${QENC}&facets=${FENC}") || exit 1
    TOTAL=$(echo "$BODY" | jq -r '.total // 0')
    echo "Total matches: $TOTAL" >&2
    echo
    echo "$BODY" | jq -r --arg f "$F" '.facets[$f][]? | "  \(.count | tostring | .[0:10])  \(.value)"' \
      | awk '{printf "  %-10s  %s\n", $1, substr($0, index($0, $2))}'
    ;;

  *)
    echo "Unknown subcommand: $CMD" >&2
    echo "Run '$0' uden args for hjælp." >&2
    exit 1
    ;;
esac

echo "" >&2
echo "Bemærk:" >&2
echo "  - Shodan-opslag er passive — data er allerede indsamlet." >&2
echo "  - 'host' og 'search' bruger query-credits; 'count' og 'info' gør ikke." >&2
echo "  - Brug IKKE resultater offensivt uden skriftlig autorisation." >&2

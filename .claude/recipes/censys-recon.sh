#!/bin/bash
# Censys recon — wrapper omkring Censys API til passive
# infrastructure-opslag. Censys er stærkest på certifikat-historik
# og host-attribuering.
#
# Auth-modes (auto-detect):
#   - Platform API: hvis $CENSYS_ENDPOINT er sat, bruges Bearer-auth
#     med $CENSYS_TOKEN. $CENSYS_USER bruges kun til log-output.
#   - Search v2 (default): hvis $CENSYS_ENDPOINT ikke er sat, bruges
#     Basic Auth med $CENSYS_USER:$CENSYS_TOKEN (klassisk API_ID:SECRET)
#     mod https://search.censys.io
#
# Subkommandoer:
#   host <ip>                Host-detaljer (services, certs, location)
#   search <query>           Host-search
#   aggregate <q> <field>    Aggregér: services.port, location.country_code, etc.
#   cert <sha256>            Cert-detaljer (issuer, SANs, validity)
#   cert-search <query>      Cert-search (default last 100 days)
#   names <ip>               Hostnames associeret med en IP
#   account                  Whoami / quota
#
# Flags:
#   --mode <platform|search-v2>   Tving auth-mode
#   --per-page <n>                Paging (default 50, max 100)
#   --cursor <c>                  Næste side fra forrige response
#
# Brug:
#   export CENSYS_USER=...
#   export CENSYS_TOKEN=...
#   ./censys-recon.sh host 8.8.8.8
#   ./censys-recon.sh search 'services.service_name: HTTP and location.country_code: DK'
#   ./censys-recon.sh aggregate 'services.service_name: SSH' services.port
#   ./censys-recon.sh cert-search 'names: example.com'
#
# Etisk note: Censys-opslag er passive (data er allerede indsamlet
# af Censys' scanners). Brug ikke resultater offensivt uden
# skriftlig autorisation.

set -uo pipefail

CMD="${1:-}"
shift || true

USER="${CENSYS_USER:-}"
TOKEN="${CENSYS_TOKEN:-}"
ENDPOINT="${CENSYS_ENDPOINT:-}"
MODE=""
PER_PAGE=50
CURSOR=""

ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --mode)     MODE="$2"; shift 2 ;;
    --per-page) PER_PAGE="$2"; shift 2 ;;
    --cursor)   CURSOR="$2"; shift 2 ;;
    --) shift; while [ $# -gt 0 ]; do ARGS+=("$1"); shift; done ;;
    *)  ARGS+=("$1"); shift ;;
  esac
done

if [ -z "$CMD" ]; then
  cat >&2 <<EOF
Usage: $0 <subcommand> [args]
  host <ip>                 Host-detaljer
  search <query>            Host-search
  aggregate <q> <field>     Aggregér (fx services.port, location.country_code)
  cert <sha256>             Cert-detaljer
  cert-search <query>       Cert-search
  names <ip>                Hostnames for IP
  account                   Whoami / quota

Flags:
  --mode <platform|search-v2>   Tving auth-mode (default: auto)
  --per-page <n>                Page-size (max 100)
  --cursor <c>                  Næste side
EOF
  exit 1
fi

if [ -z "$TOKEN" ]; then
  echo "Error: \$CENSYS_TOKEN ikke sat." >&2
  exit 1
fi

# Auto-detect mode
if [ -z "$MODE" ]; then
  if [ -n "$ENDPOINT" ]; then
    MODE="platform"
  else
    MODE="search-v2"
    ENDPOINT="https://search.censys.io"
  fi
fi

if [ "$MODE" = "search-v2" ] && [ -z "$USER" ]; then
  echo "Error: search-v2 mode kræver \$CENSYS_USER (API ID)." >&2
  exit 1
fi

UA="osint-recon-recipe/1.0 (censys-recon)"

# Trim trailing slash på endpoint
ENDPOINT="${ENDPOINT%/}"

# httpget <path> [query-string]
httpget() {
  local PATH_="$1"
  local QS="${2:-}"
  local URL="${ENDPOINT}${PATH_}"
  [ -n "$QS" ] && URL="${URL}?${QS}"

  local AUTH_ARGS=()
  if [ "$MODE" = "platform" ]; then
    AUTH_ARGS=(-H "Authorization: Bearer ${TOKEN}")
  else
    AUTH_ARGS=(-u "${USER}:${TOKEN}")
  fi

  local RESP CODE BODY
  RESP=$(curl -sSL --max-time 30 -A "$UA" \
             "${AUTH_ARGS[@]}" \
             -H "Accept: application/json" \
             -w '\n%{http_code}' \
             "$URL" 2>/dev/null)
  CODE=$(echo "$RESP" | tail -n1)
  BODY=$(echo "$RESP" | sed '$d')

  case "$CODE" in
    200) printf '%s' "$BODY"; return 0 ;;
    401|403) echo "Auth-fejl ($CODE). Tjek CENSYS_USER/TOKEN og mode=$MODE." >&2; return 1 ;;
    404) echo "Ikke fundet (404)." >&2; return 1 ;;
    422) echo "Ugyldig query (422):" >&2; echo "$BODY" | jq . >&2 2>/dev/null || echo "$BODY" >&2; return 1 ;;
    429) echo "Rate-limited (429). Vent og prøv igen." >&2; return 1 ;;
    *) echo "Uventet HTTP $CODE." >&2; echo "$BODY" >&2; return 1 ;;
  esac
}

httppost() {
  local PATH_="$1"
  local DATA="$2"
  local URL="${ENDPOINT}${PATH_}"

  local AUTH_ARGS=()
  if [ "$MODE" = "platform" ]; then
    AUTH_ARGS=(-H "Authorization: Bearer ${TOKEN}")
  else
    AUTH_ARGS=(-u "${USER}:${TOKEN}")
  fi

  local RESP CODE BODY
  RESP=$(curl -sSL --max-time 30 -A "$UA" \
             "${AUTH_ARGS[@]}" \
             -H "Accept: application/json" \
             -H "Content-Type: application/json" \
             -X POST \
             --data "$DATA" \
             -w '\n%{http_code}' \
             "$URL" 2>/dev/null)
  CODE=$(echo "$RESP" | tail -n1)
  BODY=$(echo "$RESP" | sed '$d')

  case "$CODE" in
    200) printf '%s' "$BODY"; return 0 ;;
    401|403) echo "Auth-fejl ($CODE)." >&2; return 1 ;;
    422) echo "Ugyldig request (422):" >&2; echo "$BODY" | jq . >&2 2>/dev/null || echo "$BODY" >&2; return 1 ;;
    429) echo "Rate-limited (429)." >&2; return 1 ;;
    *) echo "Uventet HTTP $CODE." >&2; echo "$BODY" >&2; return 1 ;;
  esac
}

urlenc() {
  jq -nr --arg v "$1" '$v | @uri'
}

echo "=== Censys (mode=$MODE) ===" >&2

case "$CMD" in
  host)
    IP="${ARGS[0]:-}"
    if [ -z "$IP" ]; then echo "Usage: $0 host <ip>" >&2; exit 1; fi
    BODY=$(httpget "/api/v2/hosts/${IP}") || exit 1
    echo "$BODY" | jq -r '.result // . |
      "IP:           \(.ip)",
      "Last updated: \(.last_updated_at // "n/a")",
      "Location:     \(.location.country // "n/a") / \(.location.city // "n/a")  (\(.location.country_code // "?"))",
      "AS:           AS\(.autonomous_system.asn // "?")  \(.autonomous_system.name // "")",
      "Reverse DNS:  \((.dns.reverse_dns.names // []) | join(", "))",
      "Operating sys:\(.operating_system.product // "n/a")  \(.operating_system.version // "")",
      "",
      "Services:",
      (.services[]? | "  ── \(.port)/\(.transport_protocol // "tcp")  \(.service_name // "?")  \(.extended_service_name // "")
     software:  \([(.software // [])[].product] | join(", "))
     observed:  \(.observed_at // "n/a")
     banner:    \((.banner // "" | .[0:160] | gsub("\n"; " ⏎ ")))")'
    ;;

  search)
    Q="${ARGS[*]:-}"
    if [ -z "$Q" ]; then echo "Usage: $0 search <query>" >&2; exit 1; fi
    QENC=$(urlenc "$Q")
    QS="q=${QENC}&per_page=${PER_PAGE}"
    [ -n "$CURSOR" ] && QS="${QS}&cursor=${CURSOR}"
    BODY=$(httpget "/api/v2/hosts/search" "$QS") || exit 1
    echo "Total: $(echo "$BODY" | jq -r '.result.total // .total // 0')" >&2
    echo
    echo "$BODY" | jq -r '(.result.hits // .hits)[]? |
      "── \(.ip)  [AS\(.autonomous_system.asn // "?") / \(.location.country_code // "?")]
   services:  \([.services[]? | "\(.port)/\(.service_name // "?")"] | join(", "))
   reverse:   \((.dns.reverse_dns.names // []) | join(", "))"'
    NEXT=$(echo "$BODY" | jq -r '.result.links.next // .links.next // ""')
    [ -n "$NEXT" ] && echo "Next cursor: $NEXT" >&2
    ;;

  aggregate)
    Q="${ARGS[0]:-}"
    F="${ARGS[1]:-}"
    if [ -z "$Q" ] || [ -z "$F" ]; then
      echo "Usage: $0 aggregate <query> <field>" >&2
      echo "Common fields: services.port, services.service_name, location.country_code, autonomous_system.asn" >&2
      exit 1
    fi
    QENC=$(urlenc "$Q")
    FENC=$(urlenc "$F")
    BODY=$(httpget "/api/v2/hosts/aggregate" "q=${QENC}&field=${FENC}&num_buckets=${PER_PAGE}") || exit 1
    echo "Total: $(echo "$BODY" | jq -r '.result.total // .total // 0')" >&2
    echo
    echo "$BODY" | jq -r '(.result.buckets // .buckets)[]? | "  \(.count)  \(.key)"' \
      | awk '{printf "  %-10s  %s\n", $1, substr($0, index($0, $2))}'
    ;;

  cert)
    SHA="${ARGS[0]:-}"
    if [ -z "$SHA" ]; then echo "Usage: $0 cert <sha256>" >&2; exit 1; fi
    BODY=$(httpget "/api/v2/certificates/${SHA}") || exit 1
    echo "$BODY" | jq -r '.result // . |
      "SHA256:    \(.fingerprint_sha256 // .parsed.fingerprint_sha256 // "n/a")",
      "Subject:   \(.parsed.subject_dn // "n/a")",
      "Issuer:    \(.parsed.issuer_dn // "n/a")",
      "Validity:  \(.parsed.validity.start // "?") → \(.parsed.validity.end // "?")",
      "SANs:      \([(.parsed.names // [])[]] | join(", "))"'
    ;;

  cert-search)
    Q="${ARGS[*]:-}"
    if [ -z "$Q" ]; then echo "Usage: $0 cert-search <query>" >&2; exit 1; fi
    # Cert-search bruger POST i v2
    DATA=$(jq -nc --arg q "$Q" --argjson pp "$PER_PAGE" '{q: $q, per_page: $pp}')
    BODY=$(httppost "/api/v2/certificates/search" "$DATA") || exit 1
    echo "Total: $(echo "$BODY" | jq -r '.result.total // 0')" >&2
    echo
    echo "$BODY" | jq -r '(.result.hits // [])[]? |
      "── \(.fingerprint_sha256 // .parsed.fingerprint_sha256 // "?")
   subject:  \(.parsed.subject_dn // "?")
   issuer:   \(.parsed.issuer_dn // "?")
   names:    \([(.names // .parsed.names // [])[]] | join(", "))
   validity: \(.parsed.validity.start // "?") → \(.parsed.validity.end // "?")"'
    ;;

  names)
    IP="${ARGS[0]:-}"
    if [ -z "$IP" ]; then echo "Usage: $0 names <ip>" >&2; exit 1; fi
    BODY=$(httpget "/api/v2/hosts/${IP}/names" "per_page=${PER_PAGE}") || exit 1
    echo "$BODY" | jq -r '(.result.names // .names // [])[]? | "  \(.)"'
    ;;

  account)
    BODY=$(httpget "/api/v1/account") || {
      # v1 findes ikke i alle modes — prøv v2 alternativ
      BODY=$(httpget "/api/v2/account") || exit 1
    }
    echo "$BODY" | jq .
    ;;

  *)
    echo "Unknown subcommand: $CMD" >&2
    exit 1
    ;;
esac

echo "" >&2
echo "Bemærk:" >&2
echo "  - Censys-data er allerede indsamlet — opslag er passive." >&2
echo "  - Brug 'aggregate' før 'search' for at forstå volumen." >&2
echo "  - Cert-historik er Censys' styrke vs. Shodan — udnyt 'cert-search'." >&2

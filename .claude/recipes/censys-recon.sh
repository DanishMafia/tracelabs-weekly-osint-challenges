#!/bin/bash
# Censys recon — wrapper omkring Censys APIs til passive
# infrastructure-opslag. Censys er stærkest på cert-historik
# og host-attribuering.
#
# To auth-modes (auto-detect):
#
#   Platform API v3 (Bearer PAT, nyere model):
#     export CENSYS_USER=you@example.com   # kun til log-output
#     export CENSYS_TOKEN=censys_...       # Personal Access Token
#     export CENSYS_ENDPOINT=https://api.platform.censys.io/v3
#
#   Search v2 (klassisk, Basic Auth):
#     export CENSYS_USER=<API_ID>          # UUID-format
#     export CENSYS_TOKEN=<API_SECRET>
#     # (CENSYS_ENDPOINT ikke sat → default search.censys.io)
#
# Auto-detect: hvis $CENSYS_ENDPOINT er sat → Platform; ellers Search v2.
# Override med --mode platform | search-v2.
#
# Subkommandoer (P=Platform, S=Search v2):
#   host <ip>                     [P,S]  Host-detaljer
#   hosts <ip,ip,...>             [P]    Batch host-lookup
#   timeline <ip> [--from] [--to] [P]    Historical host-timeline
#   cert <sha256>                 [P,S]  Cert-detaljer
#   certs <sha,sha,...>           [P]    Batch cert
#   web <hostname:port>           [P]    Webproperty
#   search <query>                [S]    Host-search
#   aggregate <q> <field>         [S]    Aggregate (services.port, ...)
#   cert-search <query>           [S]    Cert-search
#   account                       [S]    Quota / account info
#
# Brug:
#   ./censys-recon.sh host 8.8.8.8
#   ./censys-recon.sh hosts 8.8.8.8,1.1.1.1
#   ./censys-recon.sh cert d07b43fd...
#   ./censys-recon.sh web dns.google:443
#   ./censys-recon.sh timeline 8.8.8.8 --from 2026-04-01 --to 2026-05-27
#
# Etisk note: Censys-opslag er passive (data er allerede indsamlet
# af Censys' scanners). Brug ikke resultater offensivt uden
# skriftlig autorisation.

set -uo pipefail

CMD="${1:-}"
shift || true

USER_="${CENSYS_USER:-}"
TOKEN="${CENSYS_TOKEN:-}"
ENDPOINT="${CENSYS_ENDPOINT:-}"
MODE=""
PER_PAGE=50
FROM=""
TO=""

ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --mode)     MODE="$2"; shift 2 ;;
    --per-page) PER_PAGE="$2"; shift 2 ;;
    --from)     FROM="$2"; shift 2 ;;
    --to)       TO="$2"; shift 2 ;;
    --) shift; while [ $# -gt 0 ]; do ARGS+=("$1"); shift; done ;;
    *)  ARGS+=("$1"); shift ;;
  esac
done

if [ -z "$CMD" ]; then
  sed -n '4,40p' "$0" | sed 's/^# \{0,1\}//'
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
    ENDPOINT="https://search.censys.io/api/v2"
  fi
fi

if [ "$MODE" = "search-v2" ] && [ -z "$USER_" ]; then
  echo "Error: search-v2 mode kræver \$CENSYS_USER (API ID)." >&2
  exit 1
fi

ENDPOINT="${ENDPOINT%/}"
UA="osint-recon-recipe/1.0 (censys-recon)"

http_call() {
  # http_call <method> <path> [<body-json>] [query-string]
  local METHOD="$1" P="$2" BODY="${3:-}" QS="${4:-}"
  local URL="${ENDPOINT}${P}"
  [ -n "$QS" ] && URL="${URL}?${QS}"

  local AUTH_ARGS=()
  if [ "$MODE" = "platform" ]; then
    AUTH_ARGS=(-H "Authorization: Bearer ${TOKEN}")
  else
    AUTH_ARGS=(-u "${USER_}:${TOKEN}")
  fi

  local RESP CODE OUT
  if [ -n "$BODY" ]; then
    RESP=$(curl -sSL --max-time 30 -A "$UA" \
                "${AUTH_ARGS[@]}" \
                -H "Accept: application/json" \
                -H "Content-Type: application/json" \
                -X "$METHOD" --data "$BODY" \
                -w '\n%{http_code}' \
                "$URL" 2>/dev/null)
  else
    RESP=$(curl -sSL --max-time 30 -A "$UA" \
                "${AUTH_ARGS[@]}" \
                -H "Accept: application/json" \
                -X "$METHOD" \
                -w '\n%{http_code}' \
                "$URL" 2>/dev/null)
  fi
  CODE=$(echo "$RESP" | tail -n1)
  OUT=$(echo "$RESP" | sed '$d')

  case "$CODE" in
    200) printf '%s' "$OUT"; return 0 ;;
    401|403) echo "Auth-fejl ($CODE). Tjek CENSYS_USER/TOKEN i mode=$MODE." >&2; return 1 ;;
    404) echo "404: endpoint findes ikke i mode=$MODE." >&2; return 1 ;;
    422) echo "Ugyldig query/path (422):" >&2; echo "$OUT" | jq . 2>/dev/null >&2 || echo "$OUT" >&2; return 1 ;;
    429) echo "Rate-limited (429). Vent og prøv igen." >&2; return 1 ;;
    *) echo "Uventet HTTP $CODE." >&2; echo "$OUT" >&2; return 1 ;;
  esac
}

# Validér at mode er kompatibel med subkommando
require_mode() {
  local NEED="$1" CMDNAME="$2"
  if ! echo "$NEED" | grep -qw "$MODE"; then
    echo "Error: subkommando '$CMDNAME' understøttes ikke i mode=$MODE." >&2
    echo "Skift mode med --mode $(echo "$NEED" | awk '{print $1}'), eller brug en understøttet subkommando." >&2
    exit 1
  fi
}

urlenc() { jq -nr --arg v "$1" '$v | @uri'; }

echo "=== Censys (mode=$MODE) ===" >&2

case "$CMD" in
  host)
    IP="${ARGS[0]:-}"
    [ -z "$IP" ] && { echo "Usage: $0 host <ip>" >&2; exit 1; }
    if [ "$MODE" = "platform" ]; then
      BODY=$(http_call GET "/global/asset/host/${IP}") || exit 1
      ROOT='.result.resource'
    else
      BODY=$(http_call GET "/hosts/${IP}") || exit 1
      ROOT='.result'
    fi
    echo "$BODY" | jq -r "${ROOT} |
      \"IP:           \\(.ip // \"n/a\")\",
      \"Country:      \\(.location.country // \"n/a\") / \\(.location.city // \"\") (\\(.location.country_code // \"?\"))\",
      \"Coordinates:  \\(.location.coordinates.latitude // \"?\") , \\(.location.coordinates.longitude // \"?\")\",
      \"AS:           AS\\(.autonomous_system.asn // \"?\") \\(.autonomous_system.name // \"\") (\\(.autonomous_system.bgp_prefix // \"?\"))\",
      \"Reverse DNS:  \\((.dns.reverse_dns.names // []) | join(\", \"))\",
      \"Services:\",
      (.services[]? | \"  ── \\(.port)/\\(.transport_protocol // \"tcp\")  \\(.protocol // .service_name // \"?\") \\(.extended_service_name // \"\")
     scan:    \\(.scan_time // \"n/a\")
     cert:    \\(.cert.fingerprint_sha256 // \"-\")
     subject: \\(.cert.parsed.subject_dn // \"-\")\")"
    ;;

  hosts)
    require_mode "platform" "hosts"
    IPS="${ARGS[0]:-}"
    [ -z "$IPS" ] && { echo "Usage: $0 hosts <ip,ip,...>" >&2; exit 1; }
    IPSENC=$(urlenc "$IPS")
    BODY=$(http_call GET "/global/asset/host" "" "host_ids=${IPSENC}") || exit 1
    echo "$BODY" | jq -r '.result[]?.resource |
      "── \(.ip)  AS\(.autonomous_system.asn // "?") \(.autonomous_system.name // "")
   country: \(.location.country // "?")  city: \(.location.city // "?")
   ports:   \([.services[]?.port] | join(", "))"'
    ;;

  timeline)
    require_mode "platform" "timeline"
    IP="${ARGS[0]:-}"
    [ -z "$IP" ] && { echo "Usage: $0 timeline <ip> [--from YYYY-MM-DD] [--to YYYY-MM-DD]" >&2; exit 1; }
    [ -z "$FROM" ] && FROM=$(date -u -d "30 days ago" +%Y-%m-%dT00:00:00Z 2>/dev/null || date -u -v-30d +%Y-%m-%dT00:00:00Z)
    [ -z "$TO" ] && TO=$(date -u +%Y-%m-%dT00:00:00Z)
    # Normalisér YYYY-MM-DD til ISO-Z
    [[ "$FROM" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && FROM="${FROM}T00:00:00Z"
    [[ "$TO"   =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && TO="${TO}T00:00:00Z"
    QS="start_time=$(urlenc "$FROM")&end_time=$(urlenc "$TO")"
    BODY=$(http_call GET "/global/asset/host/${IP}/timeline" "" "$QS") || exit 1
    echo "Scanned to: $(echo "$BODY" | jq -r '.result.scanned_to')" >&2
    EVENTS=$(echo "$BODY" | jq -r '.result.events | length')
    echo "Events:     $EVENTS" >&2
    [ "$EVENTS" = "0" ] && echo "(ingen ændringer i perioden)" || echo "$BODY" | jq -r '.result.events[]? | "  \(.event_time // .timestamp // "?")  \(.type // "?")  \(.description // "")"'
    ;;

  cert)
    SHA="${ARGS[0]:-}"
    [ -z "$SHA" ] && { echo "Usage: $0 cert <sha256>" >&2; exit 1; }
    if [ "$MODE" = "platform" ]; then
      BODY=$(http_call GET "/global/asset/certificate/${SHA}") || exit 1
      ROOT='.result.resource'
    else
      BODY=$(http_call GET "/certificates/${SHA}") || exit 1
      ROOT='.result'
    fi
    echo "$BODY" | jq -r "${ROOT} |
      \"SHA256:    \\(.fingerprint_sha256 // \"n/a\")\",
      \"SHA1:      \\(.fingerprint_sha1 // \"n/a\")\",
      \"Subject:   \\(.parsed.subject_dn // \"n/a\")\",
      \"Issuer:    \\(.parsed.issuer_dn // \"n/a\")\",
      \"Validity:  \\(.parsed.validity_period.not_before // .parsed.validity.start // \"?\") → \\(.parsed.validity_period.not_after // .parsed.validity.end // \"?\")\",
      \"SAN-names: \\((.names // .parsed.names // []) | join(\", \"))\""
    ;;

  certs)
    require_mode "platform" "certs"
    SHAS="${ARGS[0]:-}"
    [ -z "$SHAS" ] && { echo "Usage: $0 certs <sha,sha,...>" >&2; exit 1; }
    SHASENC=$(urlenc "$SHAS")
    BODY=$(http_call GET "/global/asset/certificate" "" "certificate_ids=${SHASENC}") || exit 1
    echo "$BODY" | jq -r '.result[]?.resource |
      "── \(.fingerprint_sha256)
   subject: \(.parsed.subject_dn // "?")
   issuer:  \(.parsed.issuer_dn // "?")
   names:   \((.names // []) | join(", "))"'
    ;;

  web)
    require_mode "platform" "web"
    WP="${ARGS[0]:-}"
    [ -z "$WP" ] && { echo "Usage: $0 web <hostname:port>" >&2; exit 1; }
    WPENC=$(urlenc "$WP")
    BODY=$(http_call GET "/global/asset/webproperty/${WPENC}") || exit 1
    echo "$BODY" | jq -r '.result.resource |
      "Hostname:  \(.hostname)",
      "Port:      \(.port)",
      "Cert:      \(.cert.fingerprint_sha256 // "n/a")",
      "Subject:   \(.cert.parsed.subject_dn // "n/a")",
      "SAN-names: \((.cert.names // .cert.parsed.names // []) | join(", "))",
      "Endpoints: \([.endpoints[]? | "\(.endpoint_type // "?"):\(.port // "?")"] | join(", "))"'
    ;;

  search)
    require_mode "search-v2" "search"
    Q="${ARGS[*]:-}"
    [ -z "$Q" ] && { echo "Usage: $0 search <query>" >&2; exit 1; }
    QENC=$(urlenc "$Q")
    BODY=$(http_call GET "/hosts/search" "" "q=${QENC}&per_page=${PER_PAGE}") || exit 1
    echo "Total: $(echo "$BODY" | jq -r '.result.total // 0')" >&2
    echo "$BODY" | jq -r '.result.hits[]? |
      "── \(.ip)  [AS\(.autonomous_system.asn // "?") / \(.location.country_code // "?")]
   services:  \([.services[]? | "\(.port)/\(.service_name // "?")"] | join(", "))"'
    ;;

  aggregate)
    require_mode "search-v2" "aggregate"
    Q="${ARGS[0]:-}"; F="${ARGS[1]:-}"
    [ -z "$Q" ] || [ -z "$F" ] && { echo "Usage: $0 aggregate <query> <field>" >&2; exit 1; }
    QENC=$(urlenc "$Q"); FENC=$(urlenc "$F")
    BODY=$(http_call GET "/hosts/aggregate" "" "q=${QENC}&field=${FENC}&num_buckets=${PER_PAGE}") || exit 1
    echo "Total: $(echo "$BODY" | jq -r '.result.total // 0')" >&2
    echo "$BODY" | jq -r '.result.buckets[]? | "  \(.count)  \(.key)"' \
      | awk '{printf "  %-10s  %s\n", $1, substr($0, index($0, $2))}'
    ;;

  cert-search)
    require_mode "search-v2" "cert-search"
    Q="${ARGS[*]:-}"
    [ -z "$Q" ] && { echo "Usage: $0 cert-search <query>" >&2; exit 1; }
    DATA=$(jq -nc --arg q "$Q" --argjson pp "$PER_PAGE" '{q: $q, per_page: $pp}')
    BODY=$(http_call POST "/certificates/search" "$DATA") || exit 1
    echo "$BODY" | jq -r '.result.hits[]? |
      "── \(.fingerprint_sha256 // "?")
   subject: \(.parsed.subject_dn // "?")
   names:   \((.names // .parsed.names // []) | join(", "))"'
    ;;

  account)
    require_mode "search-v2" "account"
    BODY=$(http_call GET "/account") || exit 1
    echo "$BODY" | jq .
    ;;

  *)
    echo "Unknown subcommand: $CMD" >&2
    "$0" 2>&1 | head -30
    exit 1
    ;;
esac

echo "" >&2
echo "Bemærk:" >&2
echo "  - Censys-data er allerede indsamlet — opslag er passive." >&2
if [ "$MODE" = "platform" ]; then
  echo "  - Platform v3 PAT understøtter KUN direkte asset-lookup." >&2
  echo "    Brug 'search'/'aggregate' kræver Search v2 (API ID + secret)." >&2
fi

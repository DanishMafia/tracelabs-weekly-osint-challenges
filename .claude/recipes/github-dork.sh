#!/bin/bash
# GitHub-dork-runner — kører en serie kode-søgninger mod et target-
# domæne eller org-navn for at finde læk-mønstre (hardcoded secrets,
# config-filer, private keys).
#
# Kræver GITHUB_TOKEN env var (gratis PAT). Uden token: stærkt rate-
# limitet (10 req/min) og ofte 403.
#
# Brug:
#   export GITHUB_TOKEN=ghp_xxx
#   ./github-dork.sh example.com
#   ./github-dork.sh example.com --org acme-corp
#   ./github-dork.sh example.com --dorks-file mydorks.txt
#
# Output: én blok pr. dork, med top-5 hits (URL + path).

set -uo pipefail

TARGET="${1:-}"
ORG=""
DORKS_FILE=""

shift || true
while [ $# -gt 0 ]; do
  case "$1" in
    --org)        ORG="$2"; shift 2 ;;
    --dorks-file) DORKS_FILE="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 <domain> [--org <name>] [--dorks-file <path>]" >&2
      exit 0 ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

if [ -z "$TARGET" ]; then
  echo "Usage: $0 <domain> [--org <name>] [--dorks-file <path>]" >&2
  exit 1
fi

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "Advarsel: GITHUB_TOKEN ikke sat. Forventer 403/rate-limit." >&2
  echo "Lav en PAT på https://github.com/settings/tokens (public_repo scope)." >&2
fi

AUTH_HEADER=""
[ -n "${GITHUB_TOKEN:-}" ] && AUTH_HEADER="Authorization: Bearer $GITHUB_TOKEN"

# Default dork-bibliotek. Hver linje = ekstra query der tilføjes target.
DEFAULT_DORKS=$(cat <<'EOF'
"password"
"BEGIN RSA PRIVATE KEY"
"BEGIN OPENSSH PRIVATE KEY"
filename:.env
filename:wp-config.php
filename:config.php "password"
filename:credentials.json
filename:id_rsa
filename:.git-credentials
extension:pem
extension:pkcs12
"AKIA" "secret"
"AWS_SECRET_ACCESS_KEY"
"SLACK_TOKEN"
"DISCORD_TOKEN"
"smtp.gmail.com" "password"
EOF
)

if [ -n "$DORKS_FILE" ]; then
  if [ ! -f "$DORKS_FILE" ]; then
    echo "Error: dorks-file '$DORKS_FILE' findes ikke" >&2
    exit 1
  fi
  DORKS=$(cat "$DORKS_FILE")
else
  DORKS="$DEFAULT_DORKS"
fi

echo "=== GitHub-dork-scan ===" >&2
echo "Target: $TARGET${ORG:+  (org: $ORG)}" >&2
echo "Dorks:  $(echo "$DORKS" | grep -c .)" >&2
echo >&2

ORG_QUALIFIER=""
[ -n "$ORG" ] && ORG_QUALIFIER="org:$ORG "

while IFS= read -r DORK; do
  [ -z "$DORK" ] && continue
  QUERY="${ORG_QUALIFIER}\"${TARGET}\" ${DORK}"
  ENCODED=$(printf '%s' "$QUERY" | jq -sRr @uri)

  echo "--- DORK: $DORK ---"
  RESP=$(curl -sS --max-time 20 \
              -H "Accept: application/vnd.github+json" \
              -H "X-GitHub-Api-Version: 2022-11-28" \
              ${AUTH_HEADER:+-H "$AUTH_HEADER"} \
              "https://api.github.com/search/code?q=${ENCODED}&per_page=5" 2>/dev/null)

  TOTAL=$(echo "$RESP" | jq -r '.total_count // 0' 2>/dev/null)
  if [ "$TOTAL" = "null" ] || [ -z "$TOTAL" ]; then
    MSG=$(echo "$RESP" | jq -r '.message // "ukendt fejl"' 2>/dev/null)
    echo "  Error: $MSG"
    echo
    sleep 2
    continue
  fi

  echo "  Total hits: $TOTAL"
  echo "$RESP" | jq -r '.items[]? | "  - \(.repository.full_name): \(.path)\n    \(.html_url)"' 2>/dev/null
  echo
  sleep 2   # respektér rate-limit (30 req/min for code search auth'd)
done <<< "$DORKS"

echo "Bemærk:" >&2
echo "  - Kun mod skriftligt autoriseret scope." >&2
echo "  - Find != bekræftet leak. Validér manuelt: er secret stadig aktiv?" >&2
echo "  - Brug gitleaks/trufflehog mod klonet repo for git-historik." >&2

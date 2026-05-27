#!/bin/bash
# Lookalike-domain-tjek. Bruger dnstwist hvis installeret, ellers
# en intern fallback der genererer typo-permutationer og spørger DoH
# om de er registreret.
#
# Brug:
#   ./dnstwist-wrap.sh example.com
#   ./dnstwist-wrap.sh example.com --only-registered
#   ./dnstwist-wrap.sh example.com --concurrency 20

set -uo pipefail

DOMAIN="${1:-}"
ONLY_REGISTERED=false
CONCURRENCY=10

shift || true
while [ $# -gt 0 ]; do
  case "$1" in
    --only-registered) ONLY_REGISTERED=true; shift ;;
    --concurrency)     CONCURRENCY="$2"; shift 2 ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

if [ -z "$DOMAIN" ]; then
  echo "Usage: $0 <domain> [--only-registered] [--concurrency N]" >&2
  exit 1
fi

if ! echo "$DOMAIN" | grep -qE '^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'; then
  echo "Error: ugyldigt domæne '$DOMAIN'" >&2
  exit 1
fi

# Hvis dnstwist er installeret, brug det
if command -v dnstwist >/dev/null 2>&1; then
  echo "=== dnstwist (installeret) ===" >&2
  ARGS=("--format" "json" "--threads" "$CONCURRENCY")
  $ONLY_REGISTERED && ARGS+=("--registered")
  dnstwist "${ARGS[@]}" "$DOMAIN" \
    | jq -r '.[] | "\(.fuzzer | .[0:14])  \(.domain | .[0:40])  \((.dns_a // [.dns_aaaa // ["(none)"]] | flatten | join(","))[0:40])"'
  exit 0
fi

echo "dnstwist ikke installeret — bruger intern fallback." >&2
echo "(Installer: pip install dnstwist for fuld coverage.)" >&2
echo >&2

# Fallback: simple permutationer
BASE="${DOMAIN%%.*}"
TLD="${DOMAIN#*.}"

generate_perms() {
  local b="$1"
  local len=${#b}

  # Character omission
  for ((i=0; i<len; i++)); do
    echo "${b:0:i}${b:i+1}"
  done

  # Character substitution (homoglyphs)
  echo "$b" | sed 's/o/0/g'
  echo "$b" | sed 's/l/1/g'
  echo "$b" | sed 's/i/1/g'
  echo "$b" | sed 's/e/3/g'
  echo "$b" | sed 's/a/4/g'
  echo "$b" | sed 's/s/5/g'

  # Adjacent swap
  for ((i=0; i<len-1; i++)); do
    echo "${b:0:i}${b:i+1:1}${b:i:1}${b:i+2}"
  done

  # Common typos: doubled char, missing dash
  echo "${b}-"
  echo "-${b}"
  echo "${b}1"
  echo "${b}s"
  echo "my${b}"
  echo "${b}login"
  echo "${b}secure"
}

# Common TLD-swaps
TLD_VARIANTS=("com" "net" "org" "co" "io" "info" "biz" "online" "shop" "app")

check_domain() {
  local D="$1"
  local A
  A=$(curl -fsSL --max-time 5 "https://dns.google/resolve?name=${D}&type=A" 2>/dev/null \
      | jq -r '.Answer[]? | select(.type==1) | .data' 2>/dev/null \
      | head -3 | tr '\n' ',' | sed 's/,$//')
  if [ -n "$A" ]; then
    printf '  REGISTERED   %-40s  %s\n' "$D" "$A"
  elif ! $ONLY_REGISTERED; then
    printf '  free?        %-40s  -\n' "$D"
  fi
}

export -f check_domain
export ONLY_REGISTERED

echo "=== Lookalike-tjek (fallback): $DOMAIN ===" >&2

# Same TLD, varied base
PERMS=$(generate_perms "$BASE" | sort -u | grep -v "^$BASE\$" | grep -v "^$")
# Same base, varied TLD
for V in "${TLD_VARIANTS[@]}"; do
  [ "$V" = "$TLD" ] && continue
  PERMS=$(printf '%s\n%s' "$PERMS" "$BASE.$V")
done

# Skab fulde domæner med oprindelig TLD for perm-base
echo "$PERMS" | while IFS= read -r P; do
  [ -z "$P" ] && continue
  if [[ "$P" == *.* ]]; then
    echo "$P"
  else
    echo "${P}.${TLD}"
  fi
done | sort -u | while IFS= read -r FULL; do
  while [ "$(jobs -rp | wc -l)" -ge "$CONCURRENCY" ]; do
    wait -n 2>/dev/null || sleep 0.1
  done
  check_domain "$FULL" &
done
wait

echo "" >&2
echo "Bemærk:" >&2
echo "  - Registered = A-record findes. Ikke nødvendigvis ondsindet." >&2
echo "  - Pivotér til whois + cert-historik for hvert hit." >&2
echo "  - Brug rigtig dnstwist for IDN/homoglyph-coverage." >&2

#!/bin/bash
# brand-permutations — udvidet domæne-permutations-generator.
# Komplementerer dnstwist-wrap.sh med flere kategorier:
#   - Char omission, insertion, repetition, swap
#   - Homoglyph (latin-look-alikes: o→0, l→1, i→1, e→3, a→4, s→5)
#   - IDN-homoglyph (cyrillic а, о, е, р, с m.fl.)
#   - Bitsquatting (1-bit flip på hver karakter)
#   - Hyphenation + concatenation
#   - Subdomain-prefix ("secure-", "login-", "my-")
#   - Common-prefix ("dk-", "the-", "official-")
#   - TLD-variations (40+ TLDs)
#
# Output: liste af kandidat-domæner, valgfrit med DoH-resolve.
#
# Brug:
#   ./brand-permutations.sh nationalbanken.dk                 # generér kandidater
#   ./brand-permutations.sh nationalbanken.dk --resolve       # + DNS-lookup
#   ./brand-permutations.sh nationalbanken.dk --resolve --only-registered

set -uo pipefail

DOMAIN="${1:-}"
RESOLVE=false
ONLY_REGISTERED=false
shift || true
while [ $# -gt 0 ]; do
  case "$1" in
    --resolve)         RESOLVE=true; shift ;;
    --only-registered) ONLY_REGISTERED=true; RESOLVE=true; shift ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

if [ -z "$DOMAIN" ]; then
  echo "Usage: $0 <domain> [--resolve] [--only-registered]" >&2
  exit 1
fi

BASE="${DOMAIN%%.*}"
TLD="${DOMAIN#*.}"

# Generér permutationer
gen_omit() {
  local b="$1" len=${#1}
  for ((i=0; i<len; i++)); do echo "${b:0:i}${b:i+1}"; done
}

gen_insert() {
  local b="$1" len=${#1}
  local chars="abcdefghijklmnopqrstuvwxyz0123456789-"
  for ((i=0; i<=len; i++)); do
    for ((j=0; j<${#chars}; j++)); do
      local c="${chars:j:1}"
      echo "${b:0:i}${c}${b:i}"
    done
  done | sort -u | head -40   # cap insertions
}

gen_repeat() {
  local b="$1" len=${#1}
  for ((i=0; i<len; i++)); do echo "${b:0:i}${b:i:1}${b:i:1}${b:i+1}"; done
}

gen_swap() {
  local b="$1" len=${#1}
  for ((i=0; i<len-1; i++)); do
    echo "${b:0:i}${b:i+1:1}${b:i:1}${b:i+2}"
  done
}

gen_homoglyph_ascii() {
  local b="$1"
  echo "$b" | sed 's/o/0/g'
  echo "$b" | sed 's/l/1/g'
  echo "$b" | sed 's/i/1/g'
  echo "$b" | sed 's/e/3/g'
  echo "$b" | sed 's/a/4/g'
  echo "$b" | sed 's/s/5/g'
  # Combined
  echo "$b" | sed 's/i/l/g'   # i ↔ l
  echo "$b" | sed 's/l/i/g'
}

gen_idn_homoglyph() {
  local b="$1"
  # Replace each latin char with cyrillic look-alike using python if available
  # else use a small static set
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "
import sys, idna
b = sys.argv[1]
homo = {'a': 'а', 'e': 'е', 'o': 'о', 'p': 'р', 'c': 'с', 'x': 'х', 'y': 'у'}
seen=set()
for k, v in homo.items():
    if k in b:
        cand = b.replace(k, v, 1)
        try:
            enc = idna.encode(cand).decode()
            if enc != b and enc not in seen:
                seen.add(enc)
                print(enc)
        except Exception:
            pass
" "$b" 2>/dev/null
  fi
}

gen_bitsquat() {
  local b="$1" len=${#1}
  # Flip each bit of each char that lands in [a-z0-9-]
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "
import sys
b = sys.argv[1]
allowed = set('abcdefghijklmnopqrstuvwxyz0123456789-')
seen = set()
for i, ch in enumerate(b):
    for bit in range(8):
        nc = chr(ord(ch) ^ (1 << bit))
        if nc in allowed and nc != ch:
            cand = b[:i] + nc + b[i+1:]
            if cand != b and cand not in seen:
                seen.add(cand)
                print(cand)
" "$b" 2>/dev/null
  fi
}

gen_prefix_suffix() {
  local b="$1"
  for p in secure mit my login official dk the; do
    echo "${p}-${b}"
    echo "${p}${b}"
  done
  for s in -dk -login -official -secure -app dk; do
    echo "${b}${s}"
  done
}

gen_tld_variants() {
  local b="$1"
  for t in com net org io co eu dk se no fi de uk fr nl es it be cz pl pt at ch \
           xyz top vip site store club fun online live shop bank finance \
           tech app dev cloud pro biz info trade ventures partners cards loan; do
    [ "$t" = "$TLD" ] && continue
    echo "${b}.${t}"
  done
}

# Generate everything
{
  # Same TLD, permuted base
  for variant in $(gen_omit "$BASE" | sort -u); do echo "${variant}.${TLD}"; done
  for variant in $(gen_insert "$BASE" | sort -u | head -40); do echo "${variant}.${TLD}"; done
  for variant in $(gen_repeat "$BASE" | sort -u); do echo "${variant}.${TLD}"; done
  for variant in $(gen_swap "$BASE" | sort -u); do echo "${variant}.${TLD}"; done
  for variant in $(gen_homoglyph_ascii "$BASE" | sort -u); do echo "${variant}.${TLD}"; done
  for variant in $(gen_bitsquat "$BASE" | sort -u); do echo "${variant}.${TLD}"; done
  for variant in $(gen_prefix_suffix "$BASE" | sort -u); do echo "${variant}.${TLD}"; done
  for variant in $(gen_idn_homoglyph "$BASE" | sort -u); do echo "${variant}.${TLD}"; done

  # Same base, different TLD
  gen_tld_variants "$BASE"
} | sort -u | grep -v "^${DOMAIN}$" | grep -v '^$' > /tmp/permutations.txt

TOTAL=$(wc -l < /tmp/permutations.txt)
echo "=== Brand-permutations for $DOMAIN ===" >&2
echo "Genererede $TOTAL unikke kandidater" >&2

if ! $RESOLVE; then
  cat /tmp/permutations.txt
  exit 0
fi

# Resolve each via DoH
echo "Resolver via DoH..." >&2
HITS=0
while IFS= read -r D; do
  [ -z "$D" ] && continue
  A=$(curl -sSL --max-time 4 "https://dns.google/resolve?name=${D}&type=A" 2>/dev/null \
      | jq -r '.Answer[]? | select(.type==1) | .data' 2>/dev/null | head -1)
  if [ -n "$A" ] && [ "$A" != "null" ]; then
    printf "  REGISTERED  %-40s  %s\n" "$D" "$A"
    HITS=$((HITS+1))
  elif ! $ONLY_REGISTERED; then
    printf "  free?       %-40s  -\n" "$D"
  fi
done < /tmp/permutations.txt

echo "" >&2
echo "Resolveret: $HITS registreret af $TOTAL kandidater" >&2
echo "Bemærk:" >&2
echo "  - Bredere coverage end dnstwist-wrap.sh (inkluderer IDN, bitsquat, prefix)" >&2
echo "  - Pivotér registrede til whois/RDAP + headers-security for ejer-vurdering" >&2

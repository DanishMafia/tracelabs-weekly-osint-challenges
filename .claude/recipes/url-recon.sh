#!/bin/bash
# URL/domain recon — passiv rekognoscering af et domæne uden at
# kontakte selve serveren. Bruger Certificate Transparency (crt.sh),
# DNS-over-HTTPS (dns.google), urlscan.io og Wayback Machine.
#
# Brug:
#   ./url-recon.sh example.com
#   ./url-recon.sh https://example.com/path

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <domain-or-url>" >&2
  exit 1
fi

INPUT="$1"

# Træk domæne ud af URL
DOMAIN=$(echo "$INPUT" | sed -E 's,^https?://,,; s,/.*,,; s,:[0-9]+$,,')

if ! echo "$DOMAIN" | grep -qE '^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'; then
  echo "Error: ugyldigt domæne '$DOMAIN'" >&2
  exit 1
fi

echo "=== URL/Domain Recon ==="
echo "Domæne: $DOMAIN"
echo

# DNS A/AAAA/MX/NS/TXT via dns.google
echo "[DNS — dns.google DoH]"
for RTYPE in A AAAA MX NS TXT CNAME; do
  RESP=$(curl -fsSL --max-time 10 "https://dns.google/resolve?name=${DOMAIN}&type=${RTYPE}" 2>/dev/null || echo '{}')
  ANSWERS=$(echo "$RESP" | jq -r '.Answer[]? | "  \(.type|tostring|sub("1";"A")|sub("28";"AAAA")|sub("15";"MX")|sub("2";"NS")|sub("16";"TXT")|sub("5";"CNAME"))  \(.data)"' 2>/dev/null || true)
  if [ -n "$ANSWERS" ]; then
    echo "[$RTYPE]"
    echo "$ANSWERS"
  fi
done
echo

# Certificate Transparency via crt.sh — finder subdomæner
echo "[Certificate Transparency — crt.sh]"
CT=$(curl -fsSL --max-time 30 "https://crt.sh/?q=%25.${DOMAIN}&output=json" 2>/dev/null || echo '[]')
SUBS=$(echo "$CT" | jq -r '.[].name_value' 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr ',' '\n' | sed 's/\*\.//' | sort -u | head -30 || true)
if [ -n "$SUBS" ]; then
  echo "$SUBS" | sed 's/^/  /'
  TOTAL_CT=$(echo "$SUBS" | wc -l | tr -d ' ')
  echo "  ($TOTAL_CT unikke navne — viste max 30)"
else
  echo "  (ingen CT-poster fundet)"
fi
echo

# Wayback Machine — har siden været arkiveret?
echo "[Wayback Machine]"
WB=$(curl -fsSL --max-time 15 "https://archive.org/wayback/available?url=${DOMAIN}" 2>/dev/null || echo '{}')
WB_URL=$(echo "$WB" | jq -r '.archived_snapshots.closest.url // "(ingen)"' 2>/dev/null)
WB_TS=$(echo "$WB" | jq -r '.archived_snapshots.closest.timestamp // "n/a"' 2>/dev/null)
echo "  Seneste snapshot:  $WB_TS"
echo "  URL:               $WB_URL"
echo "  Tidslinje:         https://web.archive.org/web/*/${DOMAIN}"
echo

# urlscan.io — offentlige scans
echo "[urlscan.io — offentlige scans]"
US=$(curl -fsSL --max-time 15 "https://urlscan.io/api/v1/search/?q=domain:${DOMAIN}&size=5" 2>/dev/null || echo '{}')
SCAN_COUNT=$(echo "$US" | jq -r '.total // 0' 2>/dev/null)
echo "  Total scans: $SCAN_COUNT"
echo "$US" | jq -r '.results[]? | "  \(.task.time)  \(.page.country // "?")  https://urlscan.io/result/\(._id)/"' 2>/dev/null | head -5
echo

# Deep-links til manuel uddybning
echo "[Deep-links — åbn manuelt]"
cat <<EOF
  WHOIS:           https://www.whois.com/whois/${DOMAIN}
  Shodan:          https://www.shodan.io/search?query=hostname%3A${DOMAIN}
  Censys:          https://search.censys.io/search?resource=hosts&q=${DOMAIN}
  SecurityTrails:  https://securitytrails.com/domain/${DOMAIN}/dns
  DNSDumpster:     https://dnsdumpster.com/  (paste ${DOMAIN})
  Wayback CDX:     http://web.archive.org/cdx/search/cdx?url=${DOMAIN}&limit=20
EOF
echo
echo "Bemærk: alt ovenstående er PASSIVT — ingen probes mod ${DOMAIN}."
echo "Følg op med osint-infrastructure skill for aktiv rekon (kun med tilladelse)."

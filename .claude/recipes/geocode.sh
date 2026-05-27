#!/bin/bash
# Geocoding — koordinat ↔ stednavn via OSM Nominatim.
# Ingen API-nøgle. Følger Nominatim's Usage Policy (≤1 req/sek,
# User-Agent påkrævet).
#
# Brug:
#   ./geocode.sh "37.8199,-122.4783"            # reverse
#   ./geocode.sh "Golden Gate Bridge"           # forward
#   ./geocode.sh "Golden Gate Bridge" --bbox    # inkludér bbox

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage:" >&2
  echo "  $0 \"<lat>,<lon>\"        # reverse geocoding" >&2
  echo "  $0 \"<place name>\"       # forward geocoding" >&2
  exit 1
fi

QUERY="$1"
BBOX_FLAG="${2:-}"
UA="tracelabs-osint-recipe/1.0 (educational use)"
BASE="https://nominatim.openstreetmap.org"

urlencode() {
  python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$1"
}

if echo "$QUERY" | grep -qE '^-?[0-9]+(\.[0-9]+)?,-?[0-9]+(\.[0-9]+)?$'; then
  # Reverse geocoding
  LAT=$(echo "$QUERY" | cut -d, -f1)
  LON=$(echo "$QUERY" | cut -d, -f2)
  echo "=== Reverse Geocode ==="
  echo "Input: $LAT, $LON"
  echo

  URL="${BASE}/reverse?format=jsonv2&lat=${LAT}&lon=${LON}&zoom=18&addressdetails=1&accept-language=en"
  RESP=$(curl -fsSL --max-time 15 -A "$UA" "$URL" 2>/dev/null || echo '{}')

  if [ "$(echo "$RESP" | jq -r '.error // empty')" ]; then
    echo "Error: $(echo "$RESP" | jq -r '.error')"
    exit 1
  fi

  echo "Display name:"
  echo "  $(echo "$RESP" | jq -r '.display_name // "(ingen)"')"
  echo
  echo "Address breakdown:"
  echo "$RESP" | jq -r '.address // {} | to_entries[] | "  \(.key): \(.value)"' 2>/dev/null
  echo
  echo "OSM type/id: $(echo "$RESP" | jq -r '.osm_type // "?"' )/$(echo "$RESP" | jq -r '.osm_id // "?"')"
  echo "OSM link:    https://www.openstreetmap.org/$(echo "$RESP" | jq -r '.osm_type // "node"' | head -c1)$(echo "$RESP" | jq -r '.osm_type // "node"' | tail -c +2)/$(echo "$RESP" | jq -r '.osm_id // ""')"
  echo "GMaps:       https://www.google.com/maps/@${LAT},${LON},19z"
  echo "Bing Maps:   https://www.bing.com/maps?cp=${LAT}~${LON}&lvl=18"

else
  # Forward geocoding
  echo "=== Forward Geocode ==="
  echo "Input: $QUERY"
  echo

  Q_ENC=$(urlencode "$QUERY")
  URL="${BASE}/search?q=${Q_ENC}&format=jsonv2&addressdetails=1&limit=5&accept-language=en"
  RESP=$(curl -fsSL --max-time 15 -A "$UA" "$URL" 2>/dev/null || echo '[]')

  COUNT=$(echo "$RESP" | jq 'length' 2>/dev/null || echo 0)
  if [ "$COUNT" = "0" ]; then
    echo "(Ingen resultater)"
    exit 0
  fi

  echo "$RESP" | jq -r '.[] | "
[\(.type) | \(.class)]  importance=\(.importance|tostring|.[0:4])
  \(.display_name)
  lat,lon:   \(.lat), \(.lon)
  OSM:       https://www.openstreetmap.org/\(.osm_type|.[0:1])\(.osm_type[1:])/\(.osm_id)
  GMaps:     https://www.google.com/maps/@\(.lat),\(.lon),19z"'

  if [ "$BBOX_FLAG" = "--bbox" ]; then
    echo
    echo "Bounding boxes:"
    echo "$RESP" | jq -r '.[] | "  \(.boundingbox|join(", "))"'
  fi
fi

echo
echo "Bemærk: Nominatim er rate-limited til ~1 req/sek."
echo "Til tunge workloads: kør egen Nominatim eller brug Photon."

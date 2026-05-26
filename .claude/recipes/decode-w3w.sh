#!/bin/bash
# Decode et what3words-adresse (3 ord adskilt med punktum eller skråstreg)
# til GPS-koordinater og menneske-læsbart sted.
#
# Bruger w3w.co's OG meta-tags (offentligt, ingen API-nøgle nødvendig)
# + OSM Nominatim reverse-geocoding.
#
# Brug:
#   ./decode-w3w.sh complains.bowls.fantastic
#   ./decode-w3w.sh "///complains.bowls.fantastic"

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <three.word.code>" >&2
  exit 1
fi

# Normalisér input: strip "///" prefix, brug punktum-separator
W3W="$(echo "$1" | sed -E 's|^///||; s|/|.|g')"

if ! echo "$W3W" | grep -qE '^[a-z]+\.[a-z]+\.[a-z]+$'; then
  echo "Error: '$W3W' ligner ikke en gyldig what3words-kode (3 ord adskilt med punktum)" >&2
  exit 1
fi

# Scrape OG meta — what3words.com tilbyder lat/lng i twitter/og-image URLs
HTML="$(curl -sL -H 'User-Agent: Mozilla/5.0' "https://what3words.com/$W3W")"
if [ -z "$HTML" ]; then
  echo "Error: ingen respons fra what3words.com" >&2
  exit 1
fi

LAT="$(echo "$HTML" | grep -oE 'mapapi.what3words.com/map/minimap\?lat=[-0-9.]+' | head -1 | sed 's/.*lat=//')"
LON="$(echo "$HTML" | grep -oE 'mapapi.what3words.com/map/minimap\?lat=[-0-9.]+&amp;lng=[-0-9.]+' | head -1 | sed 's/.*lng=//')"
DESC="$(echo "$HTML" | grep -oE 'twitter:description"[^"]+content="[^"]+' | head -1 | sed 's/.*content="//')"

if [ -z "$LAT" ] || [ -z "$LON" ]; then
  echo "Error: kunne ikke udtrække koordinater for '$W3W'" >&2
  exit 1
fi

echo "what3words: ///$W3W"
echo "  Koordinater: $LAT°N, $LON°E"
echo "  w3w-beskrivelse: ${DESC:-(ingen)}"
echo
echo "Reverse-geocoder via OSM Nominatim..."

ADDR="$(curl -sH 'User-Agent: tracelabs-osint (educational)' \
  "https://nominatim.openstreetmap.org/reverse?format=json&lat=$LAT&lon=$LON&zoom=18")"

DISPLAY="$(echo "$ADDR" | jq -r '.display_name // "(intet OSM-match)"')"
COUNTRY="$(echo "$ADDR" | jq -r '.address.country // "?"')"
CITY="$(echo "$ADDR" | jq -r '.address.city // .address.town // .address.village // "?"')"
ROAD="$(echo "$ADDR" | jq -r '.address.road // .address.pedestrian // "?"')"

echo "  Display:  $DISPLAY"
echo "  By:       $CITY"
echo "  Land:     $COUNTRY"
echo "  Vej:      $ROAD"
echo
echo "Maps-link:  https://www.openstreetmap.org/?mlat=$LAT&mlon=$LON&zoom=18"

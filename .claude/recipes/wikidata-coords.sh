#!/bin/bash
# Wikidata SPARQL — find præcise koordinater for et stednavn,
# eller find stednavne i nærheden af en koordinat. Bruger Wikidata's
# offentlige SPARQL-endpoint (https://query.wikidata.org/sparql).
# Ingen autentificering.
#
# Brug:
#   ./wikidata-coords.sh "Golden Gate Bridge"
#   ./wikidata-coords.sh nearby 37.8199 -122.4783 5      # 5km radius

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage:" >&2
  echo "  $0 \"<place name>\"" >&2
  echo "  $0 nearby <lat> <lon> [radius_km]" >&2
  exit 1
fi

UA="tracelabs-osint-recipe/1.0 (educational use)"
ENDPOINT="https://query.wikidata.org/sparql"

sparql() {
  local QUERY="$1"
  curl -fsSL --max-time 30 -A "$UA" \
       -G "$ENDPOINT" \
       --data-urlencode "query=$QUERY" \
       --data-urlencode "format=json" 2>/dev/null
}

if [ "$1" = "nearby" ]; then
  LAT="${2:?lat påkrævet}"
  LON="${3:?lon påkrævet}"
  RADIUS_KM="${4:-2}"
  echo "=== Wikidata nearby ($LAT, $LON, ${RADIUS_KM} km) ==="
  echo

  Q="SELECT ?place ?placeLabel ?dist ?coord WHERE {
    SERVICE wikibase:around {
      ?place wdt:P625 ?coord .
      bd:serviceParam wikibase:center \"Point($LON $LAT)\"^^geo:wktLiteral .
      bd:serviceParam wikibase:radius \"$RADIUS_KM\" .
      bd:serviceParam wikibase:distance ?dist .
    }
    SERVICE wikibase:label { bd:serviceParam wikibase:language \"en\" . }
  } ORDER BY ?dist LIMIT 20"

  RESP=$(sparql "$Q")
  echo "$RESP" | jq -r '.results.bindings[] | "  \(.dist.value|tonumber|.*1000|floor) m   \(.placeLabel.value)   \(.place.value)"' 2>/dev/null | head -20

else
  PLACE="$1"
  echo "=== Wikidata search: $PLACE ==="
  echo

  Q="SELECT ?item ?itemLabel ?coord ?countryLabel WHERE {
    ?item rdfs:label \"$PLACE\"@en .
    ?item wdt:P625 ?coord .
    OPTIONAL { ?item wdt:P17 ?country . }
    SERVICE wikibase:label { bd:serviceParam wikibase:language \"en\" . }
  } LIMIT 10"

  RESP=$(sparql "$Q")
  HITS=$(echo "$RESP" | jq -r '.results.bindings | length')

  if [ "$HITS" = "0" ] || [ -z "$HITS" ]; then
    echo "(Ingen eksakt navn-match. Prøver fuzzy via wbsearchentities...)"
    SEARCH=$(curl -fsSL --max-time 15 -A "$UA" \
      "https://www.wikidata.org/w/api.php?action=wbsearchentities&search=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$PLACE")&language=en&format=json&limit=5" \
      2>/dev/null || echo '{}')
    echo "$SEARCH" | jq -r '.search[]? | "  \(.id)  \(.label)  — \(.description // "(no desc)")"'
    echo
    echo "Hent koordinater for ID: $0 \"$(echo "$SEARCH" | jq -r '.search[0].label // ""')\""
    exit 0
  fi

  echo "$RESP" | jq -r '.results.bindings[] |
    "  \(.itemLabel.value) (\(.countryLabel.value // "?"))
    Wikidata: \(.item.value)
    Coord:    \(.coord.value | sub("Point\\("; "") | sub("\\)"; "") | split(" ") | "lat=\(.[1]), lon=\(.[0])")"' 2>/dev/null
fi

echo
echo "Bemærk: Wikidata-data er crowdsourced. Verificér mod 2+ kilder før citering."

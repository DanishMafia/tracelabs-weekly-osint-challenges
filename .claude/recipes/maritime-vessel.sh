#!/bin/bash
# Maritime OSINT — slå skibsnavn / IMO / MMSI op på tværs af åbne kilder.
#
# Anvendelse:
#   ./maritime-vessel.sh "Ever Given"
#   ./maritime-vessel.sh --imo 9811000
#   ./maritime-vessel.sh --mmsi 353136000
#
# Returnerer:
#   - VesselFinder, MarineTraffic, FleetMon søge-URLs
#   - Equasis (kræver konto — kun deep-link)
#   - GISIS IMO ship search
#   - Wikipedia/Wikidata-opslag på skibsnavnet
#
# Ingen API-nøgler påkrævet. Alle resultater er deep-links til offentlige
# kilder; følg dem manuelt i browser (rate limits + ToS).

set -euo pipefail

MODE="name"
QUERY=""

if [ $# -eq 0 ]; then
  echo "Usage:" >&2
  echo "  $0 \"<vessel-name>\"" >&2
  echo "  $0 --imo <7-digit-imo>" >&2
  echo "  $0 --mmsi <9-digit-mmsi>" >&2
  exit 1
fi

case "$1" in
  --imo)  MODE="imo";  QUERY="${2:?IMO påkrævet}" ;;
  --mmsi) MODE="mmsi"; QUERY="${2:?MMSI påkrævet}" ;;
  *)      MODE="name"; QUERY="$1" ;;
esac

urlencode() {
  python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$1"
}

Q_ENC=$(urlencode "$QUERY")

echo "=== Maritime Vessel OSINT ==="
echo "Mode:  $MODE"
echo "Query: $QUERY"
echo

case "$MODE" in
  name)
    cat <<EOF
[Search-URLs — åbn manuelt i browser]

VesselFinder:
  https://www.vesselfinder.com/vessels?name=${Q_ENC}

MarineTraffic:
  https://www.marinetraffic.com/en/ais/index/search/all/keyword:${Q_ENC}

FleetMon:
  https://www.fleetmon.com/vessels/?s=${Q_ENC}

MyShipTracking:
  https://www.myshiptracking.com/vessels?name=${Q_ENC}

Equasis (kræver gratis konto):
  https://www.equasis.org/EquasisWeb/public/HomePage

GISIS IMO ship search (officiel — kræver gratis IMO-konto):
  https://gisis.imo.org/Public/SHIPS/Default.aspx

Wikipedia (skibsnavne ofte specifikke artikler):
  https://en.wikipedia.org/w/index.php?search=${Q_ENC}+ship&fulltext=1

Wikidata:
  https://www.wikidata.org/w/index.php?search=${Q_ENC}+ship
EOF
    ;;

  imo)
    if ! echo "$QUERY" | grep -qE '^[0-9]{7}$'; then
      echo "Advarsel: IMO-numre er normalt 7 cifre. Fortsætter alligevel." >&2
    fi
    cat <<EOF
[IMO ${QUERY} — direkte deep-links]

VesselFinder:    https://www.vesselfinder.com/vessels/details/${QUERY}
MarineTraffic:   https://www.marinetraffic.com/en/ais/details/ships/imo:${QUERY}
FleetMon:        https://www.fleetmon.com/vessels/?s=${QUERY}
Equasis search:  https://www.equasis.org/EquasisWeb/restricted/Search?fs=ShipSearch (login)
GISIS:           https://gisis.imo.org/Public/SHIPS/Default.aspx (login)
EOF
    ;;

  mmsi)
    if ! echo "$QUERY" | grep -qE '^[0-9]{9}$'; then
      echo "Advarsel: MMSI er normalt 9 cifre. Fortsætter alligevel." >&2
    fi
    # Første 3 cifre = MID (Maritime Identification Digits) → flag-stat
    MID="${QUERY:0:3}"
    cat <<EOF
[MMSI ${QUERY} — direkte deep-links]

MID (flag-stat): $MID
  ITU MID-liste: https://www.itu.int/en/ITU-R/terrestrial/fmd/Pages/mid.aspx

VesselFinder:  https://www.vesselfinder.com/vessels/details/mmsi-${QUERY}
MarineTraffic: https://www.marinetraffic.com/en/ais/details/ships/mmsi:${QUERY}
AISHub:        https://www.aishub.net/vessels (søg manuelt)
EOF
    ;;
esac

echo
echo "[Wayback Machine — bevar fund]"
case "$MODE" in
  name) echo "  https://web.archive.org/web/*/vesselfinder.com/*${Q_ENC}*" ;;
  imo)  echo "  https://web.archive.org/web/*/vesselfinder.com/vessels/details/${QUERY}" ;;
  mmsi) echo "  https://web.archive.org/web/*/vesselfinder.com/vessels/details/mmsi-${QUERY}" ;;
esac

echo
echo "Bemærk:"
echo "  - AIS-data kan være forsinket eller spoofet (især for 'mørke' skibe)."
echo "  - Verificér med 2+ kilder (fx VesselFinder + MarineTraffic + Equasis)."
echo "  - Til historiske port calls: brug Equasis 'Last 10 port calls' eller"
echo "    søg på skibsnavn + dato i Wayback Machine."

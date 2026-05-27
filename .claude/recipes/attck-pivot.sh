#!/bin/bash
# MITRE ATT&CK pivot — slår op i Enterprise ATT&CK STIX-bundle (offline-cache)
# og returnerer teknik-info, related techniques, mitigations, eller groups
# der bruger en TTP.
#
# Brug:
#   ./attck-pivot.sh technique T1078        # detaljer + sub-techniques
#   ./attck-pivot.sh group APT29            # group-profil + brugte teknikker
#   ./attck-pivot.sh software Mimikatz      # software-info + teknikker
#   ./attck-pivot.sh search "credential"    # fritekst-søgning
#   ./attck-pivot.sh users-of T1003         # hvilke groups bruger T1003

set -uo pipefail

MODE="${1:-}"
QUERY="${2:-}"

if [ -z "$MODE" ] || [ -z "$QUERY" ]; then
  echo "Usage: $0 <technique|group|software|search|users-of> <value>" >&2
  exit 1
fi

ATTCK_URL="https://raw.githubusercontent.com/mitre/cti/master/enterprise-attack/enterprise-attack.json"
CACHE="/tmp/attck-enterprise.json"

if [ ! -f "$CACHE" ] || [ -n "$(find "$CACHE" -mtime +30 2>/dev/null)" ]; then
  echo "Henter MITRE ATT&CK Enterprise (~20MB)..." >&2
  curl -fsSL --max-time 60 "$ATTCK_URL" -o "$CACHE" || {
    echo "Error: kunne ikke hente ATT&CK-bundle." >&2
    exit 1
  }
fi

ext_refs_id() {
  jq -r --arg q "$1" '
    .objects[]
    | select(.external_references != null)
    | select(.external_references[]?.external_id == $q)
  '
}

case "$MODE" in
  technique)
    echo "=== ATT&CK Technique: $QUERY ===" >&2
    OBJ=$(jq -c --arg q "$QUERY" '
      .objects[]
      | select(.type=="attack-pattern")
      | select(.external_references[]?.external_id == $q)
    ' "$CACHE")
    if [ -z "$OBJ" ]; then
      echo "Ikke fundet. Tjek T-nummer-format (fx T1078, T1078.001)." >&2
      exit 1
    fi
    echo "$OBJ" | jq -r '
      "Name:        \(.name)",
      "ID:          \(.external_references[0].external_id)",
      "URL:         \(.external_references[0].url)",
      "Tactics:     \([.kill_chain_phases[]?.phase_name] | join(", "))",
      "Platforms:   \((.x_mitre_platforms // []) | join(", "))",
      "Detection:   \(.x_mitre_detection // "n/a" | .[0:300])",
      "",
      "Description:",
      (.description | .[0:600])'
    ;;

  group)
    echo "=== ATT&CK Group: $QUERY ===" >&2
    OBJ=$(jq -c --arg q "$QUERY" '
      .objects[]
      | select(.type=="intrusion-set")
      | select(.name == $q or (.aliases // []) | index($q))
    ' "$CACHE")
    if [ -z "$OBJ" ]; then
      echo "Ikke fundet. Tjek group-navn eller alias." >&2
      exit 1
    fi
    echo "$OBJ" | jq -r '
      "Name:        \(.name)",
      "Aliases:     \(.aliases // [] | join(", "))",
      "ID:          \(.external_references[0].external_id)",
      "URL:         \(.external_references[0].url)",
      "",
      "Description:",
      (.description | .[0:800])'

    GROUP_ID=$(echo "$OBJ" | jq -r '.id')
    echo
    echo "=== Teknikker brugt af $QUERY ==="
    jq -r --arg g "$GROUP_ID" '
      .objects[]
      | select(.type=="relationship")
      | select(.source_ref == $g and .relationship_type=="uses")
      | .target_ref
    ' "$CACHE" | while IFS= read -r REF; do
      jq -r --arg id "$REF" '
        .objects[]
        | select(.id == $id and .type=="attack-pattern")
        | "  - \(.external_references[0].external_id)  \(.name)"
      ' "$CACHE"
    done
    ;;

  software)
    echo "=== ATT&CK Software: $QUERY ===" >&2
    jq -r --arg q "$QUERY" '
      .objects[]
      | select(.type=="malware" or .type=="tool")
      | select(.name == $q or (.x_mitre_aliases // []) | index($q))
      | "Name:        \(.name)
Type:        \(.type)
Aliases:     \(.x_mitre_aliases // [] | join(", "))
ID:          \(.external_references[0].external_id)
URL:         \(.external_references[0].url)

Description:
\(.description | .[0:600])"
    ' "$CACHE"
    ;;

  search)
    echo "=== ATT&CK search: \"$QUERY\" ===" >&2
    jq -r --arg q "$QUERY" '
      .objects[]
      | select(.type=="attack-pattern" or .type=="intrusion-set" or .type=="malware" or .type=="tool")
      | select((.name // "" | ascii_downcase | contains($q | ascii_downcase))
            or (.description // "" | ascii_downcase | contains($q | ascii_downcase)))
      | "[\(.type)]  \(.external_references[0].external_id // "n/a")  \(.name)"
    ' "$CACHE" | head -40
    ;;

  users-of)
    echo "=== Groups/software der bruger $QUERY ===" >&2
    TECH_ID=$(jq -r --arg q "$QUERY" '
      .objects[]
      | select(.type=="attack-pattern")
      | select(.external_references[]?.external_id == $q)
      | .id
    ' "$CACHE")
    if [ -z "$TECH_ID" ]; then
      echo "Teknik ikke fundet." >&2
      exit 1
    fi
    jq -r --arg t "$TECH_ID" '
      .objects[]
      | select(.type=="relationship")
      | select(.target_ref == $t and .relationship_type=="uses")
      | .source_ref
    ' "$CACHE" | while IFS= read -r REF; do
      jq -r --arg id "$REF" '
        .objects[]
        | select(.id == $id and (.type=="intrusion-set" or .type=="malware" or .type=="tool"))
        | "  [\(.type)]  \(.external_references[0].external_id // "n/a")  \(.name)"
      ' "$CACHE"
    done
    ;;

  *)
    echo "Unknown mode: $MODE" >&2
    echo "Modes: technique | group | software | search | users-of" >&2
    exit 1
    ;;
esac

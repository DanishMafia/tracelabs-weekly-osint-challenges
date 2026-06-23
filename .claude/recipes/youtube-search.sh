#!/bin/bash
# youtube-search — YouTube Data API v3 wrapper til brand-mention og
# deepfake-discovery. Kræver YOUTUBE_API_KEY (gratis Google Cloud,
# 10k quota-units/dag default).
#
# Subkommandoer:
#   search <query>           Søg videoer
#   channel <name>           Find kanaler med navn-match
#   video <video-id>         Detaljer for video-ID
#   channel-videos <id>      Seneste videoer fra kanal-ID
#   deepfake-scan <brand>    Forberedt scan: "<brand>", "<brand> deepfake", "<brand> fake", "<brand> ai"
#
# Brug:
#   export YOUTUBE_API_KEY=<key>
#   ./youtube-search.sh search "Christian Kettel Thomsen"
#   ./youtube-search.sh deepfake-scan "Danmarks Nationalbank"
#   ./youtube-search.sh channel "Nationalbanken"

set -uo pipefail

CMD="${1:-}"
shift || true

KEY="${YOUTUBE_API_KEY:-${GOOGLE_API_KEY:-}}"
MAX=20
REGION="DK"
ORDER="date"
ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --key)    KEY="$2"; shift 2 ;;
    --max)    MAX="$2"; shift 2 ;;
    --region) REGION="$2"; shift 2 ;;
    --order)  ORDER="$2"; shift 2 ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

if [ -z "$CMD" ]; then
  cat >&2 <<EOF
Usage: $0 <subcommand> [args]
  search <query>           Video-søgning
  channel <name>           Kanal-søgning
  video <id>               Video-detaljer
  channel-videos <id>      Seneste fra kanal
  deepfake-scan <brand>    Forberedt deepfake/scam-scan

Flags:
  --max <n>        Resultater per call (max 50; default 20)
  --region <code>  Default: DK
  --order <date|rating|relevance|viewCount>   Default: date

Krav:
  export YOUTUBE_API_KEY=<key fra Google Cloud Console>
EOF
  exit 1
fi

if [ -z "$KEY" ]; then
  echo "Error: \$YOUTUBE_API_KEY ikke sat." >&2
  echo "Hent gratis key: https://console.cloud.google.com/apis/library/youtube.googleapis.com" >&2
  exit 1
fi

UA="osint-recon-recipe/1.0 (youtube-search)"
BASE="https://www.googleapis.com/youtube/v3"
urlenc() { jq -nr --arg v "$1" '$v | @uri'; }

api_call() {
  local PATH_="$1"
  local URL="${BASE}${PATH_}&key=${KEY}"
  curl -sSL --max-time 20 -A "$UA" "$URL"
}

fmt_search_videos() {
  jq -r '.items[]? | select(.id.kind == "youtube#video") |
    "── \(.snippet.publishedAt[:16])  \(.snippet.title // "" | gsub("\n"; " ") | .[0:100])
   channel:  \(.snippet.channelTitle) (\(.snippet.channelId))
   videoId:  \(.id.videoId)
   url:      https://www.youtube.com/watch?v=\(.id.videoId)
   desc:     \((.snippet.description // "") | gsub("\n"; " ⏎ ") | .[0:200])"'
}

fmt_search_channels() {
  jq -r '.items[]? | select(.id.kind == "youtube#channel") |
    "── @\(.snippet.channelTitle)  ID: \(.id.channelId)
   created:  \(.snippet.publishedAt[:10])
   desc:     \((.snippet.description // "") | gsub("\n"; " ⏎ ") | .[0:200])
   url:      https://www.youtube.com/channel/\(.id.channelId)"'
}

case "$CMD" in
  search)
    Q="${ARGS[*]:-}"
    [ -z "$Q" ] && { echo "Usage: $0 search <query>" >&2; exit 1; }
    QENC=$(urlenc "$Q")
    echo "=== YouTube search: \"$Q\" (region=$REGION, order=$ORDER) ==="
    RESP=$(api_call "/search?part=snippet&q=${QENC}&type=video&regionCode=${REGION}&order=${ORDER}&maxResults=${MAX}")
    if echo "$RESP" | jq -e '.error' >/dev/null 2>&1; then
      echo "Fejl:"
      echo "$RESP" | jq '.error'
      exit 1
    fi
    TOTAL=$(echo "$RESP" | jq -r '.pageInfo.totalResults // 0')
    echo "Total matches: $TOTAL"
    echo "$RESP" | fmt_search_videos
    ;;

  channel)
    Q="${ARGS[*]:-}"
    [ -z "$Q" ] && { echo "Usage: $0 channel <name>" >&2; exit 1; }
    QENC=$(urlenc "$Q")
    echo "=== YouTube channel search: \"$Q\" ==="
    RESP=$(api_call "/search?part=snippet&q=${QENC}&type=channel&maxResults=${MAX}")
    echo "$RESP" | fmt_search_channels
    ;;

  video)
    VID="${ARGS[0]:-}"
    [ -z "$VID" ] && { echo "Usage: $0 video <video-id>" >&2; exit 1; }
    RESP=$(api_call "/videos?part=snippet,statistics,status&id=${VID}")
    echo "$RESP" | jq -r '.items[0]? |
      "Title:     \(.snippet.title)
Channel:   \(.snippet.channelTitle) (\(.snippet.channelId))
Published: \(.snippet.publishedAt)
Views:     \(.statistics.viewCount // "?")
Likes:     \(.statistics.likeCount // "?")
Comments:  \(.statistics.commentCount // "?")
Privacy:   \(.status.privacyStatus // "?")
Embed:     \(.status.embeddable // false)
Tags:      \((.snippet.tags // []) | join(", ") | .[0:200])
Desc:
\(.snippet.description // "")"'
    ;;

  channel-videos)
    CID="${ARGS[0]:-}"
    [ -z "$CID" ] && { echo "Usage: $0 channel-videos <channel-id>" >&2; exit 1; }
    RESP=$(api_call "/search?part=snippet&channelId=${CID}&type=video&order=date&maxResults=${MAX}")
    echo "$RESP" | fmt_search_videos
    ;;

  deepfake-scan)
    B="${ARGS[*]:-}"
    [ -z "$B" ] && { echo "Usage: $0 deepfake-scan <brand>" >&2; exit 1; }
    for SUFFIX in "" " deepfake" " fake" " ai" " scam" " crypto"; do
      Q="${B}${SUFFIX}"
      QENC=$(urlenc "$Q")
      echo
      echo "--- \"$Q\" ---"
      RESP=$(api_call "/search?part=snippet&q=${QENC}&type=video&order=date&maxResults=10")
      TOTAL=$(echo "$RESP" | jq -r '.pageInfo.totalResults // 0')
      echo "  Total matches: $TOTAL"
      echo "$RESP" | jq -r '.items[]? | select(.id.kind == "youtube#video") |
        "  \(.snippet.publishedAt[:10])  @\(.snippet.channelTitle)  \(.snippet.title // "" | .[0:80])
    https://www.youtube.com/watch?v=\(.id.videoId)"' | head -30
    done
    ;;

  *)
    echo "Unknown subcommand: $CMD" >&2
    exit 1
    ;;
esac

echo "" >&2
echo "Bemærk:" >&2
echo "  - YouTube Data API gratis-tier: 10000 quota-units/dag." >&2
echo "  - search-call koster 100 units, videos-call 1, channels-call 1." >&2
echo "  - For continuous-monitoring: brug less-frequent search-calls + cheap videos-lookups." >&2

#!/bin/bash
# Wallet-tracing — initial recon på en Bitcoin- eller Ethereum-adresse.
# Bruger gratis offentlige APIs (Blockstream, Etherscan public tier).
#
# Brug:
#   ./wallet-trace.sh bc1qxxx...                    # auto-detect BTC
#   ./wallet-trace.sh 0xabcd...                     # auto-detect ETH
#   ./wallet-trace.sh 0xabcd... --tx-limit 20

set -uo pipefail

ADDR="${1:-}"
TX_LIMIT=10

shift || true
while [ $# -gt 0 ]; do
  case "$1" in
    --tx-limit) TX_LIMIT="$2"; shift 2 ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

if [ -z "$ADDR" ]; then
  echo "Usage: $0 <bitcoin-or-eth-address> [--tx-limit N]" >&2
  exit 1
fi

# Detect chain
CHAIN=""
if echo "$ADDR" | grep -qE '^0x[a-fA-F0-9]{40}$'; then
  CHAIN="eth"
elif echo "$ADDR" | grep -qE '^(bc1[a-z0-9]{8,87}|[13][a-km-zA-HJ-NP-Z1-9]{25,34})$'; then
  CHAIN="btc"
else
  echo "Error: kan ikke detektere chain. Forventer BTC ($/3/bc1...) eller ETH (0x...)." >&2
  exit 1
fi

echo "=== Wallet-trace: $ADDR ===" >&2
echo "Chain: $CHAIN" >&2
echo >&2

case "$CHAIN" in
  btc)
    BASE="https://blockstream.info/api"
    echo "[Balance + tx-count]"
    INFO=$(curl -fsSL --max-time 15 "${BASE}/address/${ADDR}" 2>/dev/null)
    if [ -z "$INFO" ]; then
      echo "  Error: ingen respons fra Blockstream API." >&2
      exit 1
    fi
    echo "$INFO" | jq -r '
      "  Funded txo count:  \(.chain_stats.funded_txo_count)",
      "  Funded total sat:  \(.chain_stats.funded_txo_sum)",
      "  Spent txo count:   \(.chain_stats.spent_txo_count)",
      "  Spent total sat:   \(.chain_stats.spent_txo_sum)",
      "  Mempool tx count:  \(.mempool_stats.funded_txo_count + .mempool_stats.spent_txo_count)"'

    BAL=$(echo "$INFO" | jq -r '(.chain_stats.funded_txo_sum - .chain_stats.spent_txo_sum) / 100000000')
    echo "  Current balance:   ${BAL} BTC"
    echo

    echo "[Seneste $TX_LIMIT transaktioner]"
    curl -fsSL --max-time 15 "${BASE}/address/${ADDR}/txs" 2>/dev/null \
      | jq -r --arg n "$TX_LIMIT" '.[0:($n|tonumber)] | .[] |
          "  \(.txid[0:16])...
            block:   \(.status.block_height // "mempool")
            time:    \((.status.block_time // 0) | strftime("%Y-%m-%d %H:%M UTC"))
            inputs:  \(.vin | length)
            outputs: \(.vout | length)
            fee:     \(.fee) sat"'
    echo
    echo "Explorer: https://mempool.space/address/${ADDR}"
    ;;

  eth)
    # Etherscan v2 free tier — kræver ingen key for basic reads i mange tilfælde,
    # men auth giver højere rate-limit.
    KEY_PARAM=""
    [ -n "${ETHERSCAN_API_KEY:-}" ] && KEY_PARAM="&apikey=$ETHERSCAN_API_KEY"

    BASE="https://api.etherscan.io/api"

    echo "[Balance]"
    BAL_WEI=$(curl -fsSL --max-time 15 \
      "${BASE}?module=account&action=balance&address=${ADDR}&tag=latest${KEY_PARAM}" 2>/dev/null \
      | jq -r '.result')
    if [ -z "$BAL_WEI" ] || [ "$BAL_WEI" = "null" ]; then
      echo "  Error: ingen balance-respons." >&2
    else
      # wei -> eth via awk (jq's bignum kan have præcisionsproblemer)
      BAL_ETH=$(awk -v w="$BAL_WEI" 'BEGIN{printf "%.6f", w/1e18}')
      echo "  Balance: ${BAL_ETH} ETH (${BAL_WEI} wei)"
    fi
    echo

    echo "[Seneste $TX_LIMIT normale tx]"
    curl -fsSL --max-time 20 \
      "${BASE}?module=account&action=txlist&address=${ADDR}&startblock=0&endblock=99999999&page=1&offset=${TX_LIMIT}&sort=desc${KEY_PARAM}" 2>/dev/null \
      | jq -r '.result[]? |
          "  \(.hash[0:18])...
            block:    \(.blockNumber)
            time:     \((.timeStamp | tonumber) | strftime("%Y-%m-%d %H:%M UTC"))
            from:     \(.from)
            to:       \(.to)
            value:    \(.value)
            method:   \(.functionName // "(transfer)")"'
    echo

    echo "[Seneste $TX_LIMIT ERC-20 transfers]"
    curl -fsSL --max-time 20 \
      "${BASE}?module=account&action=tokentx&address=${ADDR}&page=1&offset=${TX_LIMIT}&sort=desc${KEY_PARAM}" 2>/dev/null \
      | jq -r '.result[]? |
          "  \(.tokenSymbol)  \(.value)  \(.from) → \(.to)"'
    echo
    echo "Explorer: https://etherscan.io/address/${ADDR}"
    echo "Labels:   https://arkhamintelligence.com/explorer/address/${ADDR}"
    ;;
esac

echo >&2
echo "Bemærk:" >&2
echo "  - Blockchain-data er pseudonyme. Attribution kræver off-chain korrelation." >&2
echo "  - Mixer-output (Tornado Cash, Wasabi) er ikke pålideligt traceable." >&2
echo "  - Sanctions-tjek (OFAC SDN) før evt. interaktion med adresser." >&2

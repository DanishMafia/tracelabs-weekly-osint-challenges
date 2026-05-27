---
name: osint-crypto
description: Crypto- og blockchain-OSINT — wallet-tracing, transaktions-pivotering, exchange-attribution, ransomware-payment-tracking, NFT-metadata. Bitcoin, Ethereum, EVM-chains. Brug ved spørgsmål om "crypto OSINT", "wallet", "Bitcoin tracing", "Etherscan", "blockchain explorer", "ransomware payment", "tornado cash", "mixer", "NFT" eller når en kryptoadresse er artefakt.
---

# Crypto / Blockchain OSINT

Brug denne skill når sporet er en kryptoadresse, en transaktions-hash,
en exchange-konto eller en NFT. Fokus er passiv kæde-analyse af
offentlige blockchain-data — ingen private nøgler eller adgang til
private feeds.

## Workflow

1. **Identificér chain.** Bitcoin (`bc1...`, `1...`, `3...`),
   Ethereum/EVM (`0x...` 42 hex), Solana (`...` 32–44 b58), Tron
   (`T...` 34 b58), Monero (`4...` 95 b58 — privat, ikke
   traceable normalt).
2. **Slå adresse op.** Blockchain explorer for kæden. Notér første
   tx-dato, total volumen, ind/ud-mønster.
3. **Klassificér.** Hot wallet? Exchange deposit? Smart contract?
   Mixer? Ransom-payment? Brug labels fra Etherscan/Arkham/Chainabuse.
4. **Pivotér.** Pengestrøm bagud til kilde og fremad til destination.
   Notér exchanges hvor KYC kan tvinges retsligt.
5. **Cluster-analyse.** Bitcoin: common-input-heuristic — flere
   adresser i samme tx ejes ofte af samme entitet.
6. **Mixer/peel-chains.** Tornado Cash, ChipMixer, Wasabi, Samourai
   — markér break-points; kraftigt heuristisk derefter.
7. **Off-ramp.** Centralised exchanges = subpoena-mål. DEX'er har
   ingen KYC men leaves more graph-data.
8. **Triangulér.** Knyt wallet til offentlige claims (Twitter
   "tip my ETH", forum-poster, NFT-profil) for attribution.

## Værktøjer

*Blockchain explorers (gratis web):*
- [blockchain.com explorer](https://www.blockchain.com/explorer) – Bitcoin.
- [mempool.space](https://mempool.space/) – Bitcoin med rich mempool-data.
- [Etherscan](https://etherscan.io/) – Ethereum + labels.
- [BscScan](https://bscscan.com/) – BNB Chain.
- [Polygonscan](https://polygonscan.com/) – Polygon.
- [Arbiscan](https://arbiscan.io/) – Arbitrum.
- [Solscan](https://solscan.io/) – Solana.
- [Tronscan](https://tronscan.org/) – Tron (vigtig for USDT-flows).
- [Blockchair](https://blockchair.com/) – Multi-chain explorer + ren søgning.

*Attribution & clustering:*
- [Arkham Intelligence](https://www.arkhamintelligence.com/) – Wallet-labels, entity-grafer.
- [Chainabuse](https://www.chainabuse.com/) – Community-rapporterede scam-adresser.
- [Etherscan labels](https://etherscan.io/labelcloud) – Kendte exchange/DeFi-labels.
- [Bitcoin Abuse Database](https://www.bitcoinabuse.com/) – Rapporterede misbrugte BTC-adresser.
- [Cryptoscamdb](https://cryptoscamdb.org/) – Scam-domæner og -adresser.

*Pro / kommercielle:*
- [Chainalysis Reactor](https://www.chainalysis.com/) – Industri-standard kæde-analyse (betalt).
- [TRM Labs](https://www.trmlabs.com/) – Compliance & investigations.
- [Crystal](https://crystalblockchain.com/) – Blockchain analytics.
- [Elliptic](https://www.elliptic.co/) – AML + investigations.

*Programmatic:*
- [Bitquery](https://bitquery.io/) – GraphQL over multi-chain data.
- [Dune Analytics](https://dune.com/) – SQL over on-chain data.
- [The Graph](https://thegraph.com/) – Subgraphs for protocols.
- [Etherscan API](https://docs.etherscan.io/) – REST (gratis tier).

*Ransomware-specifikt:*
- [Ransomwhe.re](https://ransomwhe.re/) – Open ransomware payment tracker.
- [ID-Ransomware](https://id-ransomware.malwarehunterteam.com/) – Variant-ID fra noter/krypterede filer.

## Pivots og signaler

- **Round-number transfers** = mellem entitet-kontrol, ikke organisk
  handel.
- **Peel chains** (lille beløb ud, resten videre) er klassisk
  laundering-mønster.
- **Tornado Cash deposit** = obfuskering. Output er teknisk umuligt
  at forbinde 1:1 (men timing + beløbs-clustering hjælper).
- **Bridge-flows** (LayerZero, Wormhole) gør at sporet skifter
  chain — husk at fortsætte på destination-kæden.
- **Off-ramp til kendt exchange** = god retslig hook.

## NFT-OSINT

- Metadata ofte på IPFS (`ipfs://Qm...`) eller centraliseret URL.
- Kreator-wallet historik via OpenSea/Magic Eden.
- Reverse image search på NFT-billede kan afsløre stjålet kunst.
- C2PA-metadata (Adobe Content Credentials) på nyere NFT'er.

## Etisk note

- **Kun offentlige data.** Blockchain-data er pseudonyme men
  offentlige. Attribution kræver typisk korrelation med off-chain
  data — pas på ikke at outsource dox-arbejde gennem mellemled.
- **Mixer-output** kan ikke pålideligt tilbageføres uden access til
  proprietære clustering-data. Påberåb dig ikke certainty du ikke
  har.
- **PII i write-up:** wallet-adresser er offentlige; navne knyttet
  til dem kræver verificeret kilde og må ikke offentliggøres uden
  juridisk dækning.
- **Ransomware-payments:** at spore er passivt; at *facilitere*
  betaling kræver sanctions-tjek (OFAC SDN-list).

## Quick-ref kommandoer

```bash
# Bitcoin: hent tx + utxos (gratis, ingen key)
curl -fsSL "https://blockstream.info/api/address/<ADDR>"

# Ethereum: balance + tx (Etherscan API key gratis tier)
curl -fsSL "https://api.etherscan.io/api?module=account&action=txlist&address=<ADDR>&apikey=<KEY>"

# Bitquery (GraphQL, gratis tier):
# https://graphql.bitquery.io  -- byg query i Explorer
```

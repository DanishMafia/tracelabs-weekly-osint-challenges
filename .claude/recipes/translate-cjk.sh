#!/bin/bash
# Oversæt CJK-tekst (kinesisk, japansk, koreansk) til engelsk og dansk.
# Bruger MyMemory API (gratis, ingen nøgle) + Unicode-kode-points for
# tegn-for-tegn-verifikation.
#
# Brug:
#   ./translate-cjk.sh "我不懂中文"
#   ./translate-cjk.sh "我不懂中文" zh-CN
#   echo "你好世界" | ./translate-cjk.sh

set -euo pipefail

# Læs input
if [ $# -ge 1 ] && [ -n "$1" ]; then
  TEXT="$1"
  SRC_LANG="${2:-auto}"
else
  TEXT="$(cat)"
  SRC_LANG="auto"
fi

if [ -z "$TEXT" ]; then
  echo "Usage: $0 <cjk-text> [src-lang]" >&2
  echo "Or pipe text via stdin" >&2
  exit 1
fi

echo "=== CJK Oversættelse ==="
echo "Original: $TEXT"
echo

# Tegn-for-tegn Unicode-analyse
echo "[Tegn-for-tegn (Unicode kode-points)]"
python3 <<PYEOF
import unicodedata
import sys

text = """$TEXT"""
for ch in text:
    cp = ord(ch)
    if cp < 0x80:
        continue  # spring ASCII over
    try:
        name = unicodedata.name(ch)
    except ValueError:
        name = "(unnamed)"
    # Heuristik: traditionelt vs forenklet kinesisk
    cat = ""
    if 0x4E00 <= cp <= 0x9FFF:
        cat = "CJK Unified"
    elif 0x3400 <= cp <= 0x4DBF:
        cat = "CJK Ext-A"
    elif 0x3040 <= cp <= 0x309F:
        cat = "Hiragana (JP)"
    elif 0x30A0 <= cp <= 0x30FF:
        cat = "Katakana (JP)"
    elif 0xAC00 <= cp <= 0xD7AF:
        cat = "Hangul (KO)"
    print(f"  {ch}  U+{cp:04X}  {cat}  {name}")
PYEOF
echo

# Auto-detect sprog hvis ikke specificeret
if [ "$SRC_LANG" = "auto" ]; then
  SRC_LANG=$(python3 - <<PYEOF
text = """$TEXT"""
has_kana = any(0x3040 <= ord(c) <= 0x30FF for c in text)
has_hangul = any(0xAC00 <= ord(c) <= 0xD7AF for c in text)
has_han = any(0x4E00 <= ord(c) <= 0x9FFF for c in text)
if has_kana:
    print("ja")
elif has_hangul:
    print("ko")
elif has_han:
    print("zh-CN")
else:
    print("zh-CN")
PYEOF
)
fi
echo "Detekteret sprog: $SRC_LANG"
echo

# MyMemory API kald (gratis, ingen nøgle, op til 5000 ord/dag)
TEXT_URL=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.stdin.read().strip()))" <<< "$TEXT")

echo "[MyMemory → engelsk]"
RESP=$(curl -s "https://api.mymemory.translated.net/get?q=${TEXT_URL}&langpair=${SRC_LANG}|en")
EN=$(echo "$RESP" | jq -r '.responseData.translatedText // "(ingen oversættelse)"')
echo "  $EN"
echo

echo "[MyMemory → dansk]"
RESP=$(curl -s "https://api.mymemory.translated.net/get?q=${TEXT_URL}&langpair=${SRC_LANG}|da")
DA=$(echo "$RESP" | jq -r '.responseData.translatedText // "(ingen oversættelse)"')
echo "  $DA"
echo

# Heuristik: traditionelt vs forenklet kinesisk (kun for zh)
if [[ "$SRC_LANG" == zh* ]]; then
  echo "[Traditionel vs forenklet kinesisk]"
  TRAD_CHARS="會說國語電東車書見聽寫讀現體實對應飛馬鳥魚龍鳳鯨"
  SIMP_CHARS="会说国语电东车书见听写读现体实对应飞马鸟鱼龙凤鲸"

  HAS_TRAD=0
  HAS_SIMP=0
  for (( i=0; i<${#TEXT}; i++ )); do
    CH="${TEXT:$i:1}"
    if [[ "$TRAD_CHARS" == *"$CH"* ]]; then HAS_TRAD=1; fi
    if [[ "$SIMP_CHARS" == *"$CH"* ]]; then HAS_SIMP=1; fi
  done

  if [ "$HAS_TRAD" -eq 1 ] && [ "$HAS_SIMP" -eq 0 ]; then
    echo "  → Sandsynligvis TRADITIONEL kinesisk (Taiwan, HK, Macao)"
  elif [ "$HAS_SIMP" -eq 1 ] && [ "$HAS_TRAD" -eq 0 ]; then
    echo "  → Sandsynligvis FORENKLET kinesisk (Fastlandskina, Singapore)"
  elif [ "$HAS_TRAD" -eq 1 ] && [ "$HAS_SIMP" -eq 1 ]; then
    echo "  → Blandet — usædvanligt"
  else
    echo "  → Kunne ikke afgøre (tegn ikke i begrænset prøve-sæt)"
  fi
fi

echo
echo "Bemærk: Maskinoversættelse er ikke autoritativ."
echo "Markér tydeligt i write-up + bevar originalen + Unicode kode-points."

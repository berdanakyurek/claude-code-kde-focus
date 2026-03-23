#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; exit 1; }

echo "claude-code-kde-focus installer"
echo "================================"

# --- Bağımlılık kontrolleri ---
command -v kdotool  &>/dev/null || fail "kdotool bulunamadı. Kur: sudo dnf install kdotool"
command -v qdbus    &>/dev/null || fail "qdbus bulunamadı. Kur: sudo dnf install qt6-qttools"
command -v jq       &>/dev/null || fail "jq bulunamadı. Kur: sudo dnf install jq"
command -v kwriteconfig6 &>/dev/null || fail "kwriteconfig6 bulunamadı. Kur: sudo dnf install kf6-kconfig"
ok "Bağımlılıklar tamam"

# --- Script kurulumu ---
SCRIPT_DIR="$HOME/.local/bin"
mkdir -p "$SCRIPT_DIR"
cp "$(dirname "$0")/scripts/claude-focus.sh" "$SCRIPT_DIR/claude-focus.sh"
chmod +x "$SCRIPT_DIR/claude-focus.sh"
ok "claude-focus.sh → $SCRIPT_DIR/claude-focus.sh"

# --- Claude Code hook ayarı ---
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
mkdir -p "$(dirname "$CLAUDE_SETTINGS")"

HOOK_JSON='{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.local/bin/claude-focus.sh"
          }
        ]
      }
    ]
  }
}'

if [ ! -f "$CLAUDE_SETTINGS" ]; then
    echo "$HOOK_JSON" > "$CLAUDE_SETTINGS"
else
    # Mevcut ayarlarla birleştir (Stop hook'u ekle/güncelle)
    MERGED=$(jq -s '.[0] * .[1]' "$CLAUDE_SETTINGS" <(echo "$HOOK_JSON"))
    echo "$MERGED" > "$CLAUDE_SETTINGS"
fi
ok "Claude Code Stop hook eklendi → $CLAUDE_SETTINGS"

# --- KDE focus stealing prevention = None ---
kwriteconfig6 --file kwinrc --group Windows --key FocusStealingPreventionLevel 0
if qdbus org.kde.KWin /KWin reconfigure &>/dev/null; then
    ok "KDE Focus Stealing Prevention → None (KWin yeniden yapılandırıldı)"
else
    warn "KWin reconfigure başarısız — oturumu kapatıp açınca aktif olacak"
fi

echo ""
ok "Kurulum tamamlandı. Claude Code'u yeniden başlatmana gerek yok."

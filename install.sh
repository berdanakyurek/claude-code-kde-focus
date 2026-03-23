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

# --- Dependency checks ---
command -v kdotool       &>/dev/null || fail "kdotool not found. Install: sudo dnf install kdotool"
command -v qdbus         &>/dev/null || fail "qdbus not found. Install: sudo dnf install qt6-qttools"
command -v jq            &>/dev/null || fail "jq not found. Install: sudo dnf install jq"
command -v kwriteconfig6 &>/dev/null || fail "kwriteconfig6 not found. Install: sudo dnf install kf6-kconfig"
ok "Dependencies OK"

# --- Install script ---
SCRIPT_DIR="$HOME/.local/bin"
mkdir -p "$SCRIPT_DIR"
cp "$(dirname "$0")/scripts/claude-focus.sh" "$SCRIPT_DIR/claude-focus.sh"
chmod +x "$SCRIPT_DIR/claude-focus.sh"
ok "claude-focus.sh → $SCRIPT_DIR/claude-focus.sh"

# --- Claude Code hook ---
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
    # Merge with existing settings
    MERGED=$(jq -s '.[0] * .[1]' "$CLAUDE_SETTINGS" <(echo "$HOOK_JSON"))
    echo "$MERGED" > "$CLAUDE_SETTINGS"
fi
ok "Claude Code Stop hook added → $CLAUDE_SETTINGS"

# --- KDE focus stealing prevention = None ---
kwriteconfig6 --file kwinrc --group Windows --key FocusStealingPreventionLevel 0
if qdbus org.kde.KWin /KWin reconfigure &>/dev/null; then
    ok "KDE Focus Stealing Prevention → None (KWin reconfigured)"
else
    warn "KWin reconfigure failed — will take effect after re-login"
fi

echo ""
ok "Installation complete. No need to restart Claude Code."

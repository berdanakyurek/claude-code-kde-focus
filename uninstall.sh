#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }

echo "claude-code-kde-focus uninstaller"
echo "=================================="

# --- Remove script ---
SCRIPT="$HOME/.local/bin/claude-focus.sh"
if [ -f "$SCRIPT" ]; then
    rm "$SCRIPT"
    ok "Removed $SCRIPT"
else
    warn "$SCRIPT not found, skipping"
fi

# --- Remove Claude Code Stop hook ---
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
if [ -f "$CLAUDE_SETTINGS" ]; then
    CLEANED=$(jq 'del(.hooks.Stop)' "$CLAUDE_SETTINGS")
    # Remove .hooks entirely if now empty
    CLEANED=$(echo "$CLEANED" | jq 'if .hooks == {} then del(.hooks) else . end')
    echo "$CLEANED" > "$CLAUDE_SETTINGS"
    ok "Claude Code Stop hook removed → $CLAUDE_SETTINGS"
else
    warn "$CLAUDE_SETTINGS not found, skipping"
fi

# --- Restore KDE focus stealing prevention to default (Medium = 2) ---
kwriteconfig6 --file kwinrc --group Windows --key FocusStealingPreventionLevel 2
if qdbus org.kde.KWin /KWin reconfigure &>/dev/null; then
    ok "KDE Focus Stealing Prevention → Medium/default (KWin reconfigured)"
else
    warn "KWin reconfigure failed — will take effect after re-login"
fi

echo ""
ok "Uninstall complete."

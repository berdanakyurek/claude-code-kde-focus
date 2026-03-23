#!/bin/bash
# Claude Code - Konsole penceresini ve doğru tab'ı öne çıkar

# Konsole penceresini aktif et
WINDOW_ID=$(kdotool search --class konsole 2>/dev/null | head -1)
if [ -n "$WINDOW_ID" ]; then
    kdotool windowactivate "$WINDOW_ID"
fi

# Doğru Konsole tab'ına geç (KONSOLE_DBUS_SESSION=/Sessions/3 -> id=3)
if [ -n "$KONSOLE_DBUS_SERVICE" ] && [ -n "$KONSOLE_DBUS_SESSION" ]; then
    SESSION_ID="${KONSOLE_DBUS_SESSION##*/}"
    qdbus "$KONSOLE_DBUS_SERVICE" /Windows/1 \
        org.kde.konsole.Window.setCurrentSession "$SESSION_ID" 2>/dev/null
fi

notify-send "Claude Code" "Hazır" -i utilities-terminal 2>/dev/null

exit 0

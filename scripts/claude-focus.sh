#!/bin/bash
# Claude Code - Terminal penceresini ve doğru tab'ı öne çıkar (KDE Wayland)

# PPID zincirini tarayarak terminal emülatörünün penceresini bul
WINDOW_ID=""
pid=$(ps -o ppid= -p $$ 2>/dev/null | tr -d ' ')
for _ in $(seq 1 15); do
    [ -z "$pid" ] || [ "$pid" -le 1 ] && break
    wid=$(kdotool search --pid "$pid" 2>/dev/null | head -1)
    if [ -n "$wid" ]; then
        WINDOW_ID="$wid"
        break
    fi
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
done

if [ -n "$WINDOW_ID" ]; then
    kdotool windowactivate "$WINDOW_ID"
fi

# Tab switching: terminal tipine göre
if [ -n "$KONSOLE_DBUS_SERVICE" ] && [ -n "$KONSOLE_DBUS_SESSION" ]; then
    # Konsole ve Yakuake (Konsole backend kullanır)
    SESSION_ID="${KONSOLE_DBUS_SESSION##*/}"
    qdbus "$KONSOLE_DBUS_SERVICE" /Windows/1 \
        org.kde.konsole.Window.setCurrentSession "$SESSION_ID" 2>/dev/null

elif [ -n "$KITTY_LISTEN_ON" ] && [ -n "$KITTY_WINDOW_ID" ]; then
    # Kitty (allow_remote_control + listen_on gerektirir)
    kitty @ --to "$KITTY_LISTEN_ON" focus-window \
        --match "id:$KITTY_WINDOW_ID" 2>/dev/null

elif [ -n "$WEZTERM_PANE" ]; then
    # WezTerm
    wezterm cli activate-pane --pane-id "$WEZTERM_PANE" 2>/dev/null
fi
# Diğer terminaller: tab switching yok, pencere zaten yukarıda öne getirildi

notify-send "Claude Code" "Ready" -i utilities-terminal 2>/dev/null

exit 0

#!/bin/bash
# Claude Code - Terminal penceresini ve doğru tab'ı öne çıkar (KDE Wayland)

# Process adından kdotool class adını döndür
terminal_class() {
    case "$1" in
        konsole)               echo "konsole" ;;
        kitty)                 echo "kitty" ;;
        alacritty)             echo "Alacritty" ;;
        wezterm-gui)           echo "org.wezfurlong.wezterm" ;;
        foot)                  echo "foot" ;;
        tilix)                 echo "tilix" ;;
        xterm)                 echo "xterm" ;;
        gnome-terminal-server) echo "gnome-terminal-server" ;;
    esac
}

# PPID zincirini tarayarak terminal adını tespit et, --class ile pencereyi bul
WINDOW_ID=""
pid=$(ps -o ppid= -p $$ 2>/dev/null | tr -d ' ')
for _ in $(seq 1 15); do
    [ -z "$pid" ] || [ "$pid" -le 1 ] && break
    pname=$(ps -o comm= -p "$pid" 2>/dev/null)
    class=$(terminal_class "$pname")
    if [ -n "$class" ]; then
        WINDOW_ID=$(kdotool search --class "$class" 2>/dev/null | head -1)
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

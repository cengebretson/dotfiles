#!/usr/bin/env bash
# Swap the appearance.conf symlink between the two themes (prefix + T).
# tmux.conf re-sources the config after running this.
set -u

THEME1="$HOME/.config/tmux/appearance1.conf"
THEME2="$HOME/.config/tmux/appearance2.conf"
CURRENT_LINK="$HOME/.config/tmux/appearance.conf"

# An unreadable/missing link yields an empty target and falls through to THEME1.
ACTIVE_TARGET=$(readlink "$CURRENT_LINK" 2>/dev/null || true)

if [ "$ACTIVE_TARGET" = "$THEME1" ]; then
    ln -sf "$THEME2" "$CURRENT_LINK"
else
    ln -sf "$THEME1" "$CURRENT_LINK"
fi


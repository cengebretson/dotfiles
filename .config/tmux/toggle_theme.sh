#!/bin/sh

THEME1="$HOME/.config/tmux/appearance1.conf"
THEME2="$HOME/.config/tmux/appearance2.conf"
CURRENT_LINK="$HOME/.config/tmux/appearance.conf"

# 1. Swap the symlink
ACTIVE_TARGET=$(readlink "$CURRENT_LINK")

if [ "$ACTIVE_TARGET" = "$THEME1" ]; then
    ln -sf "$THEME2" "$CURRENT_LINK"
    NEW_THEME="Theme 2"
else
    ln -sf "$THEME1" "$CURRENT_LINK"
    NEW_THEME="Theme 1"
fi


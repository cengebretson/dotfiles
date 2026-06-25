#!/usr/bin/env bash
# tmux status-bar indicator for the Moshi agent-hook daemon (3-state).
#   dim   "off" -> daemon stopped
#   amber "on"  -> daemon up but NOT paired (won't actually push)
#   green "on"  -> daemon up AND paired (really pushing)
# Catppuccin Mocha hex so both themes render consistently.
#
# Daemon up/down is checked every refresh with pgrep (instant). Pairing changes
# rarely and `moshi-hook status` touches Keychain (slow / can block headless), so
# pairing is read from the cached tmux option @moshi_paired (seeded at tmux load
# and refreshed by moshi-notify) rather than queried here.
if ! pgrep -f "moshi-hook serve" >/dev/null 2>&1; then
    printf '#[fg=#6c7086]󰄛 off'          # dim
    exit 0
fi
if [ "$(tmux show-option -gqv @moshi_paired)" = "yes" ]; then
    printf '#[fg=#a6e3a1]󰄛 on'           # green: up + paired
else
    printf '#[fg=#f9e2af]󰄛 on'           # amber: up, unpaired
fi

#!/usr/bin/env bash
# Toggle the Moshi agent-hook daemon and report the *landed* state on the tmux
# status line. Invoked (backgrounded) from the 󰄛 status indicator click and from
# `prefix + N` (see tmux.conf). The toggle goes through the moshi-notify fish
# function, run via a login fish for PATH; its own output is discarded so it does
# not dump brew chatter into the active pane.
#
# State mirrors moshi_status.sh so the message matches the indicator's colour:
#   dim   -> daemon stopped (OFF)
#   green -> running + paired
#   amber -> running + unpaired
fish -l -c 'moshi-notify toggle' >/dev/null 2>&1

if ! pgrep -f "moshi-hook serve" >/dev/null 2>&1; then
    tmux display-message -d 2500 "#[fg=#6c7086]󰄛 Moshi notifications OFF"
elif [ "$(tmux show-option -gqv @moshi_paired)" = "yes" ]; then
    tmux display-message -d 2500 "#[fg=#a6e3a1]󰄛 Moshi notifications ON (paired)"
else
    tmux display-message -d 2500 "#[fg=#f9e2af]󰄛 Moshi notifications ON (unpaired)"
fi

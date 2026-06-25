#!/usr/bin/env bash
# client-detached hook handler: reap any "phone-*" grouped mirror that no longer
# has a client attached, so the mirrors are ephemeral (they exist only while the
# phone is connected) and never clutter the solo laptop workflow or fzf-jump.
#
# Sweeps all sessions rather than trusting the detaching client's identity (which
# is unreliable at detach time). Killing a grouped session does not affect the
# real session it was grouped with.
tmux list-sessions -F '#{session_name} #{session_attached}' 2>/dev/null | while read -r name attached; do
    case "$name" in
        phone-*)
            [ "$attached" = "0" ] && tmux kill-session -t "=$name"
            ;;
    esac
done

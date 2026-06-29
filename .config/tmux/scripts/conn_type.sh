#!/usr/bin/env bash
# Maintain @conn_type (remote|local) for a session, based on whether the
# attaching client propagated SSH_CONNECTION into the session environment via
# tmux's update-environment. Read by the status bar (appearance2.conf) to show a
# remote-connection indicator. Invoked from client hooks in tmux.conf with the
# session name as $1.
set -uo pipefail

session=${1:-}
[ -n "$session" ] || exit 0

if tmux show-environment -t "$session" SSH_CONNECTION 2>/dev/null | grep -q '^SSH_CONNECTION='; then
    tmux set-option -t "$session" @conn_type remote
else
    tmux set-option -t "$session" @conn_type local
fi

#!/usr/bin/env bash
# client-attached hook handler: when a NARROW client (the phone) attaches to a
# normal session, transparently move it onto a grouped "phone-<session>" mirror
# so it shares the windows but keeps its own size, never reshaping the laptop's
# view of that session. Wide clients (the laptop) are left alone.
#
# Args (passed by the tmux hook): <client-name> <client-width> <client-session>
# Width is the phone heuristic: anything under PHONE_MAX_COLS is treated as the
# phone. A laptop in a tiny split could trip this; that is the accepted tradeoff
# for hands-off behavior (see moshi-remote-agent-setup spec, section 4).
PHONE_MAX_COLS=80

client="$1"
width="$2"
session="$3"

[ -n "$client" ] || exit 0
# Only act on narrow clients; non-numeric width also bails out here.
[ "$width" -lt "$PHONE_MAX_COLS" ] 2>/dev/null || exit 0
# Already on a mirror (or any phone-* session): nothing to do, prevents loops.
case "$session" in
    phone-*) exit 0 ;;
esac

mirror="phone-$session"
tmux has-session -t "=$mirror" 2>/dev/null || tmux new-session -d -s "$mirror" -t "$session"
tmux switch-client -c "$client" -t "=$mirror"

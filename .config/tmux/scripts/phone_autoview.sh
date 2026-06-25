#!/usr/bin/env bash
# client-attached / client-session-changed hook handler: when a NARROW client
# (the phone) lands on a normal session, by attaching OR by switching/jumping to
# it (e.g. picking it from fzf-jump), transparently move it onto a grouped
# "phone-<session>" mirror so it shares the windows but keeps its own size, never
# reshaping the laptop's view of that session. Wide clients (the laptop) are left
# alone. The window the client landed on is preserved in the mirror.
#
# Args (passed by the tmux hook): <client-name> <client-width> <client-session>
# Width is the phone heuristic: anything under PHONE_MAX_COLS is treated as the
# phone. A laptop in a tiny split could trip this; that is the accepted tradeoff
# for hands-off behavior (see moshi-remote-agent-setup spec, section 4).
#
# The threshold is the shared @phone_max_cols tmux option (set in tmux.conf) so
# the status-bar collapse and this mirror logic can never drift apart. Fallback
# to 80 if the option is unset (e.g. script run outside the normal tmux config).
PHONE_MAX_COLS=$(tmux show-option -gqv @phone_max_cols)
[ -n "$PHONE_MAX_COLS" ] || PHONE_MAX_COLS=80

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
# The window the client just landed on (the picker's target). Grouped sessions
# share windows by id, so we point the mirror at the same window to keep the jump.
target_win=$(tmux display-message -p -t "$client" '#{window_id}' 2>/dev/null)
tmux has-session -t "=$mirror" 2>/dev/null || tmux new-session -d -s "$mirror" -t "$session"
[ -n "$target_win" ] && tmux select-window -t "${mirror}:${target_win}" 2>/dev/null
tmux switch-client -c "$client" -t "=$mirror"

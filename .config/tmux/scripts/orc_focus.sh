#!/usr/bin/env bash
# prefix + F: attach to the orc-managed session that most needs attention.
#
# Deliberately distinct from M-J (tmux-fzf-jump), which covers every pane on the
# server with no prerequisites. This one is narrower and ranks orc-managed
# sessions by workflow priority, so it answers "which ticket needs me" rather
# than "which agent needs me".
#
# orc is optional here: neither the binary nor a workspace is required for the
# rest of this config. Report what is missing instead of failing opaquely, so a
# keypress explains itself rather than looking broken.
set -u

if ! command -v orc >/dev/null 2>&1; then
	tmux display-message "orc: not on PATH — install it or drop this binding"
	exit 0
fi

workspace="${ORC_WORKSPACE:-}"
if [ -z "$workspace" ]; then
	tmux display-message "orc: set ORC_WORKSPACE to your orc workspace first"
	exit 0
fi

if [ ! -f "$workspace/orc.yaml" ]; then
	tmux display-message "orc: no orc.yaml in $workspace — run 'orc init' there"
	exit 0
fi

exec orc --workspace "$workspace" focus

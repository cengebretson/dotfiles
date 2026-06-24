#!/usr/bin/env bash
set -u

event="${1:-}"
payload="$(cat)"

run_with_payload() {
  printf '%s' "$payload" | "$@"
}

have() {
  command -v "$1" >/dev/null 2>&1
}

case "$event" in
  notification)
    script="$HOME/.config/tmux/plugins/tmux-attention/scripts/tmux-attention"
    [ -x "$script" ] && "$script" input >/dev/null 2>&1 || true
    ;;
  prompt-clear)
    script="$HOME/.config/tmux/plugins/tmux-attention/scripts/tmux-attention"
    [ -x "$script" ] && "$script" clear >/dev/null 2>&1 || true
    ;;
  stop-failure)
    script="$HOME/.config/tmux/plugins/tmux-attention/scripts/tmux-attention"
    [ -x "$script" ] && "$script" blocked >/dev/null 2>&1 || true
    ;;
  format-on-edit)
    script="$HOME/.config/claude/hooks/format-on-edit.sh"
    [ -x "$script" ] && run_with_payload "$script" || true
    ;;
  context-mode-cache-heal)
    script="$HOME/.config/claude/hooks/context-mode-cache-heal.mjs"
    [ -f "$script" ] && run_with_payload "$script" || true
    ;;
  moshi)
    if have moshi-hook; then
      run_with_payload moshi-hook claude-hook || true
    elif [ -x /opt/homebrew/bin/moshi-hook ]; then
      run_with_payload /opt/homebrew/bin/moshi-hook claude-hook || true
    fi
    ;;
  *)
    exit 0
    ;;
esac

exit 0

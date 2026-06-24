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
  permission-request-notify)
    script="$HOME/.config/tmux/plugins/tmux-attention/scripts/tmux-attention"
    [ -x "$script" ] && "$script" input >/dev/null 2>&1 || true
    ;;
  prompt-clear)
    script="$HOME/.config/tmux/plugins/tmux-attention/scripts/tmux-attention"
    [ -x "$script" ] && "$script" clear >/dev/null 2>&1 || true
    ;;
  moshi)
    if have moshi-hook; then
      run_with_payload moshi-hook codex-hook || true
    elif [ -x /opt/homebrew/bin/moshi-hook ]; then
      run_with_payload /opt/homebrew/bin/moshi-hook codex-hook || true
    fi
    ;;
  *)
    exit 0
    ;;
esac

exit 0

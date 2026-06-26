#!/usr/bin/env bash
# Generic Codex hook dispatcher.
#
# Health/readiness checks live in ~/.local/bin/ai-doctor — this script only dispatches.
# Keeps hooks.json portable by routing machine-specific hook commands here.
# Future ideas:
# - Add repo-specific local hook handoff for trusted worktrees.
# - Add feature flags for optional integrations during troubleshooting.
# - Add bounded execution if a portable timeout tool becomes available.
#
# Do not log hook payloads; they may contain prompt data.
set -u

event="${1:-}"
payload="$(cat)"
log_dir="$HOME/.config/codex/hooks/logs"
log_file="$log_dir/hooks.log"

log_hook() {
  mkdir -p "$log_dir" >/dev/null 2>&1 || return 0
  printf '%s event=%s status=%s detail=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$event" "${1:-unknown}" "${2:-}" >> "$log_file" 2>/dev/null || true
}

run_with_payload() {
  label="$1"
  shift
  if printf '%s' "$payload" | "$@" >/dev/null 2>&1; then
    log_hook ok "$label"
  else
    log_hook failed "$label:rc=$?"
  fi
  return 0
}

run_command() {
  label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    log_hook ok "$label"
  else
    log_hook failed "$label:rc=$?"
  fi
  return 0
}

have() {
  command -v "$1" >/dev/null 2>&1
}

case "$event" in
  permission-request-notify)
    script="$HOME/.config/tmux/plugins/tmux-attention/scripts/tmux-attention"
    [ -x "$script" ] && run_command tmux-attention-input "$script" input || log_hook skipped tmux-attention-missing
    ;;
  prompt-clear)
    script="$HOME/.config/tmux/plugins/tmux-attention/scripts/tmux-attention"
    [ -x "$script" ] && run_command tmux-attention-clear "$script" clear || log_hook skipped tmux-attention-missing
    ;;
  moshi)
    if have moshi-hook; then
      run_with_payload moshi-hook moshi-hook codex-hook
    elif [ -x /opt/homebrew/bin/moshi-hook ]; then
      run_with_payload moshi-hook /opt/homebrew/bin/moshi-hook codex-hook
    else
      log_hook skipped moshi-hook-missing
    fi
    ;;
  *)
    log_hook skipped unknown-event
    exit 0
    ;;
esac

exit 0

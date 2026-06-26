#!/usr/bin/env bash
# Generic Claude hook dispatcher.
#
# Health/readiness checks live in ~/.local/bin/ai-doctor — this script only dispatches.
# Keeps settings.json portable by routing machine-specific hook commands here.
# Future ideas:
# - Add repo-specific local hook handoff for trusted worktrees.
# - Add feature flags for optional integrations during troubleshooting.
# - Add bounded execution if a portable timeout tool becomes available.
#
# Do not log hook payloads; they may contain prompt or file data.
set -u

event="${1:-}"
payload="$(cat)"
log_dir="$HOME/.config/claude/hooks/logs"
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
  notification)
    script="$HOME/.config/tmux/plugins/tmux-attention/scripts/tmux-attention"
    if [ -x "$script" ]; then run_command tmux-attention-input "$script" input; else log_hook skipped tmux-attention-missing; fi
    ;;
  prompt-clear)
    script="$HOME/.config/tmux/plugins/tmux-attention/scripts/tmux-attention"
    if [ -x "$script" ]; then run_command tmux-attention-clear "$script" clear; else log_hook skipped tmux-attention-missing; fi
    ;;
  stop-failure)
    script="$HOME/.config/tmux/plugins/tmux-attention/scripts/tmux-attention"
    if [ -x "$script" ]; then run_command tmux-attention-blocked "$script" blocked; else log_hook skipped tmux-attention-missing; fi
    ;;
  format-on-edit)
    script="$HOME/.config/claude/hooks/format-on-edit.sh"
    if [ -x "$script" ]; then run_with_payload format-on-edit "$script"; else log_hook skipped format-on-edit-missing; fi
    ;;
  context-mode-cache-heal)
    script="$HOME/.config/claude/hooks/context-mode-cache-heal.mjs"
    if [ -f "$script" ]; then run_with_payload context-mode-cache-heal "$script"; else log_hook skipped context-mode-cache-heal-missing; fi
    ;;
  moshi)
    if have moshi-hook; then
      run_with_payload moshi-hook moshi-hook claude-hook
    elif [ -x /opt/homebrew/bin/moshi-hook ]; then
      run_with_payload moshi-hook /opt/homebrew/bin/moshi-hook claude-hook
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

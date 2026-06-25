#!/usr/bin/env bash
# Generic Claude hook dispatcher.
#
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

doctor_line() {
  status="$1"
  label="$2"
  detail="${3:-}"
  if [ -n "$detail" ]; then
    printf '%s %s: %s\n' "$status" "$label" "$detail"
  else
    printf '%s %s\n' "$status" "$label"
  fi
}

check_dispatch_config() {
  config_file="$1"
  if [ -f "$config_file" ] && grep -q 'dispatch.sh' "$config_file"; then
    doctor_line "ok" "config" "$config_file routes through dispatch.sh"
  else
    doctor_line "warn" "config" "$config_file does not mention dispatch.sh"
  fi
}

doctor() {
  doctor_line "Claude Hook Dispatcher Doctor" ""
  [ -x "$HOME/.config/claude/hooks/dispatch.sh" ] && doctor_line ok dispatcher executable || doctor_line fail dispatcher not-executable
  if mkdir -p "$log_dir" >/dev/null 2>&1 && : >> "$log_file" 2>/dev/null; then
    doctor_line ok logging "$log_file writable"
  else
    doctor_line warn logging "$log_file not writable"
  fi
  script="$HOME/.config/tmux/plugins/tmux-attention/scripts/tmux-attention"
  [ -x "$script" ] && doctor_line ok tmux-attention "$script" || doctor_line warn tmux-attention missing
  if have moshi-hook; then
    doctor_line ok moshi-hook "$(command -v moshi-hook)"
  elif [ -x /opt/homebrew/bin/moshi-hook ]; then
    doctor_line ok moshi-hook /opt/homebrew/bin/moshi-hook
  else
    doctor_line warn moshi-hook missing
  fi
  [ -x "$HOME/.config/claude/hooks/format-on-edit.sh" ] && doctor_line ok format-on-edit present || doctor_line warn format-on-edit missing
  [ -f "$HOME/.config/claude/hooks/context-mode-cache-heal.mjs" ] && doctor_line ok context-mode-cache-heal present || doctor_line warn context-mode-cache-heal missing
  # approve-compound-bash hook + its deps (fails closed/inert if any are missing)
  [ -x "$HOME/.config/claude/hooks/approve-compound-bash.sh" ] && doctor_line ok approve-compound-bash present || doctor_line warn approve-compound-bash missing
  have shfmt && doctor_line ok shfmt "$(command -v shfmt)" || doctor_line warn shfmt "missing (approve-compound-bash falls through)"
  if [ -x /opt/homebrew/bin/bash ] || [ -x /usr/local/bin/bash ]; then
    doctor_line ok modern-bash present
  else
    doctor_line warn modern-bash "missing (approve-compound-bash needs bash 4.3+ via Homebrew; macOS ships 3.2)"
  fi
  check_dispatch_config "$HOME/.config/claude/settings.json"
}

case "$event" in
  doctor)
    doctor
    ;;
  notification)
    script="$HOME/.config/tmux/plugins/tmux-attention/scripts/tmux-attention"
    [ -x "$script" ] && run_command tmux-attention-input "$script" input || log_hook skipped tmux-attention-missing
    ;;
  prompt-clear)
    script="$HOME/.config/tmux/plugins/tmux-attention/scripts/tmux-attention"
    [ -x "$script" ] && run_command tmux-attention-clear "$script" clear || log_hook skipped tmux-attention-missing
    ;;
  stop-failure)
    script="$HOME/.config/tmux/plugins/tmux-attention/scripts/tmux-attention"
    [ -x "$script" ] && run_command tmux-attention-blocked "$script" blocked || log_hook skipped tmux-attention-missing
    ;;
  format-on-edit)
    script="$HOME/.config/claude/hooks/format-on-edit.sh"
    [ -x "$script" ] && run_with_payload format-on-edit "$script" || log_hook skipped format-on-edit-missing
    ;;
  context-mode-cache-heal)
    script="$HOME/.config/claude/hooks/context-mode-cache-heal.mjs"
    [ -f "$script" ] && run_with_payload context-mode-cache-heal "$script" || log_hook skipped context-mode-cache-heal-missing
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

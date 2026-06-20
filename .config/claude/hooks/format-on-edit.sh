#!/usr/bin/env bash
# PostToolUse hook: auto-format the file Claude just edited.
#
# Design notes / rejected alternatives:
# - Config-aware on purpose: prettier runs via `npx --no-install`, so it only
#   acts in projects that actually have prettier installed locally (and picks up
#   their config). black/isort auto-discover pyproject.toml up-tree, so they
#   respect per-project line length. This avoids reformatting random files with
#   global defaults that fight the repo style.
# - Fail-open always (exit 0): a formatter being missing or erroring must never
#   block the edit or surface a hook failure.
# - Caveat: because this mutates the file after the edit, a second Edit to the
#   same file in the same turn may need a re-Read if formatting shifted bytes.
set -u

# Hooks may run with a minimal PATH that lacks the mise shims, so tools like
# prettier/stylua/npx won't resolve. Prepend the shims dir to guarantee
# resolution (mirrors the pre-commit python3.11 PATH workaround). Python
# formatting (black/isort) only runs if those are installed; on this host they
# live in Docker/pre-commit, so the py branch is a harmless no-op until then.
export PATH="$HOME/.local/share/mise/shims:$PATH"

input="$(cat)"
fp="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
[ -n "$fp" ] || exit 0
[ -f "$fp" ] || exit 0

have() { command -v "$1" >/dev/null 2>&1; }

case "${fp##*.}" in
  js | jsx | ts | tsx | vue | json | jsonc | css | scss | less | html | md | yaml | yml)
    have npx && (cd "$(dirname "$fp")" && npx --no-install prettier --write "$fp") >/dev/null 2>&1
    ;;
  py)
    have black && black -q "$fp" >/dev/null 2>&1
    have isort && isort -q "$fp" >/dev/null 2>&1
    ;;
  lua)
    have stylua && stylua "$fp" >/dev/null 2>&1
    ;;
esac

exit 0

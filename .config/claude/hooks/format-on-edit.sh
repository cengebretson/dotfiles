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
# resolution. Python
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
    # Run from the repo root, not the file's directory: prettier resolves .prettierignore from its cwd, so
    # running from los/templates/account/ skipped the repo's `*.html` ignore and broke a Django template
    # (FLYWL-5935, 2026-11-09). Outside a git repo, fall back to the file's directory.
    root="$(git -C "$(dirname "$fp")" rev-parse --show-toplevel 2>/dev/null || dirname "$fp")"
    have npx && (cd "$root" && npx --no-install prettier --write "$fp") >/dev/null 2>&1
    ;;
  py)
    have black && black -q "$fp" >/dev/null 2>&1
    have isort && isort -q "$fp" >/dev/null 2>&1
    ;;
  lua)
    have stylua && stylua "$fp" >/dev/null 2>&1
    ;;
  fish)
    # fish_indent is canonical and has no per-project config, so the
    # "don't fight repo style" caveat above does not apply. Closes the loop
    # with `doctor dotfiles`, which format-checks tracked fish files.
    have fish_indent && fish_indent -w "$fp" >/dev/null 2>&1
    ;;
esac
# Deliberately no shfmt branch: doctor only syntax/ShellChecks bash, never
# format-checks it, so there is no drift to close — and shfmt's defaults
# (spaces) would fight these dotfiles' tabs in every repo lacking .editorconfig.

exit 0

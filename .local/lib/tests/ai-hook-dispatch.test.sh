#!/usr/bin/env bash
# Tests for the shared agent hook dispatcher (~/.local/bin/ai-hook-dispatch).
# Each case runs the real dispatcher through a temporary hooks dir, so handlers/
# and logs/ resolve next to the symlink exactly as they do for Claude and Codex.
# Run by `doctor dotfiles`; also runnable on its own.
set -euo pipefail

dispatcher="${AI_HOOK_DISPATCH:-$HOME/.local/bin/ai-hook-dispatch}"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/ai-hook-dispatch-test.XXXXXX")"
trap 'rm -rf "$test_root"' EXIT

mkdir -p "$test_root/handlers"
ln -s "$dispatcher" "$test_root/dispatch.sh"
log="$test_root/logs/hooks.log"

# make_handler NAME EXIT_CODE writes a handler that echoes its payload and exits
# with the given code.
make_handler() {
	# shellcheck disable=SC2016  # the handler body is written literally
	printf '#!/usr/bin/env bash\npayload="$(cat)"\nprintf "%%s" "$payload"\nexit %s\n' "$2" >"$test_root/handlers/$1"
	chmod +x "$test_root/handlers/$1"
}

# check LABEL COMMAND... runs a check and reports it, failing the run on error.
check() {
	local label="$1"
	shift
	if "$@"; then
		printf 'ok - %s\n' "$label"
	else
		printf 'not ok - %s\n' "$label" >&2
		exit 1
	fi
}

payload='{"event":"test"}'

make_handler passing 0
output="$(printf '%s' "$payload" | "$test_root/dispatch.sh" passing)"
check "stdout passes through to the agent" test "$output" = "$payload"
check "exit 0 logs ok" grep -q 'event=passing status=ok detail=passing' "$log"

make_handler failing 7
printf '%s' "$payload" | "$test_root/dispatch.sh" failing >/dev/null
check "nonzero exit logs failed with the code" grep -q 'event=failing status=failed detail=failing:rc=7' "$log"

make_handler skipping 100
printf '%s' "$payload" | "$test_root/dispatch.sh" skipping >/dev/null
check "exit 100 logs a skipped prerequisite" grep -q 'event=skipping status=skipped detail=skipping:prerequisite-missing' "$log"

rc=0
printf '%s' "$payload" | "$test_root/dispatch.sh" missing >/dev/null || rc=$?
check "a missing handler exits 0" test "$rc" -eq 0
check "a missing handler logs no-handler" grep -q 'event=missing status=skipped detail=no-handler:missing' "$log"

printf '%s' "$payload" | "$test_root/dispatch.sh" ../invalid >/dev/null
check "path-like event names are refused" grep -q 'status=skipped detail=invalid-event' "$log"

AI_HOOK_LOG_MAX_BYTES=1 bash -c 'printf "%s" "$1" | "$2" passing >/dev/null' _ "$payload" "$test_root/dispatch.sh"
check "an oversized log rotates to one backup" test -f "$log.1"
check "the rotated log starts fresh" test "$(wc -l <"$log" | tr -d ' ')" -eq 1

printf 'all checks passed\n'

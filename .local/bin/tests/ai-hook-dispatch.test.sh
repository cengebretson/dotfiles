#!/usr/bin/env bash
set -euo pipefail

dispatcher="$HOME/.local/bin/ai-hook-dispatch"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/ai-hook-dispatch-test.XXXXXX")"
trap 'rm -rf "$test_root"' EXIT

mkdir -p "$test_root/handlers"
ln -s "$dispatcher" "$test_root/dispatch.sh"
cat >"$test_root/handlers/example" <<'EOF'
#!/usr/bin/env bash
payload="$(cat)"
printf '%s' "$payload"
exit 7
EOF
chmod +x "$test_root/handlers/example"

payload='{"event":"test"}'
output="$(printf '%s' "$payload" | "$test_root/dispatch.sh" example)"
[[ "$output" = "$payload" ]]
grep -q 'event=example status=failed detail=example:rc=7' "$test_root/logs/hooks.log"

printf '%s' "$payload" | "$test_root/dispatch.sh" ../invalid >/dev/null
grep -q 'status=skipped detail=invalid-event' "$test_root/logs/hooks.log"

#!/usr/bin/env bash
set -euo pipefail

git_release="$HOME/.local/bin/git-release"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/git-release-test.XXXXXX")"
trap 'rm -rf "$test_root"' EXIT

failures=0

pass() { printf 'ok - %s\n' "$1"; }
fail() {
  printf 'not ok - %s\n' "$1" >&2
  failures=$((failures + 1))
}

assert_eq() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$actual" = "$expected" ]]; then pass "$name"; else fail "$name (expected '$expected', got '$actual')"; fi
}

new_repo() {
  local repo="$1"
  git init -q -b main "$repo"
  git -C "$repo" config user.name Test
  git -C "$repo" config user.email test@example.com
  git -C "$repo" config commit.gpgsign false
  git -C "$repo" config tag.gpgsign false
  git -C "$repo" remote add origin https://github.com/example/release-test.git
  printf '0.1.0\n' >"$repo/VERSION"
  cat >"$repo/CHANGELOG.md" <<'EOF'
# Changelog

## [Unreleased]

- Test release behavior.

## [0.1.0] - 2026-01-01
EOF
  printf 'original\n' >"$repo/user.txt"
  git -C "$repo" add VERSION CHANGELOG.md user.txt
  git -C "$repo" commit -qm initial
}

rollback_repo="$test_root/rollback"
new_repo "$rollback_repo"
rollback_head="$(git -C "$rollback_repo" rev-parse HEAD)"
cat >"$rollback_repo/.release-sync" <<'EOF'
#!/usr/bin/env bash
printf 'concurrent edit\n' >user.txt
exit 42
EOF
chmod +x "$rollback_repo/.release-sync"
git -C "$rollback_repo" add .release-sync
git -C "$rollback_repo" commit -qm 'add failing release hook'
rollback_head="$(git -C "$rollback_repo" rev-parse HEAD)"

if (cd "$rollback_repo" && GIT_RELEASE_TEST_CMD=true "$git_release" patch --no-fetch >/dev/null 2>&1); then
  fail "failed release returns nonzero"
else
  pass "failed release returns nonzero"
fi
assert_eq "failed release restores HEAD" "$rollback_head" "$(git -C "$rollback_repo" rev-parse HEAD)"
assert_eq "failed release preserves working-tree edits" "concurrent edit" "$(tr -d '\n' <"$rollback_repo/user.txt")"
if git -C "$rollback_repo" rev-parse -q --verify refs/tags/v0.1.1 >/dev/null; then
  fail "failed release removes its tag"
else
  pass "failed release removes its tag"
fi

success_repo="$test_root/success"
new_repo "$success_repo"
(cd "$success_repo" && GIT_RELEASE_TEST_CMD=true "$git_release" patch --no-fetch >/dev/null)
assert_eq "successful release advances VERSION" "0.1.1" "$(tr -d '\n' <"$success_repo/VERSION")"
assert_eq "successful release creates tag" "v0.1.1" "$(git -C "$success_repo" describe --tags --exact-match)"
assert_eq "successful release leaves a clean tree" "" "$(git -C "$success_repo" status --porcelain)"

exit "$failures"

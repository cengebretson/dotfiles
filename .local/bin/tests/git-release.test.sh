#!/usr/bin/env bash
# Unit tests for the git-release helper library.
#
# git-release gates every release across the tmux plugin repos and orc, and it
# had no tests: a stale hard-coded count in one repo's release-check reached CI
# twice before anyone noticed. These cover the pure functions — version
# arithmetic, changelog rewriting, test-runner resolution — which is where a
# wrong answer silently produces a bad release rather than an obvious error.
set -uo pipefail

lib_dir="${GIT_RELEASE_LIB_DIR:-$HOME/.local/lib/git-release}"
for module in common version changelog; do
	# shellcheck source=/dev/null
	source "$lib_dir/$module.sh"
done

failures=0
checks=0

ok() {
	checks=$((checks + 1))
	printf 'ok - %s\n' "$1"
}

fail() {
	checks=$((checks + 1))
	failures=$((failures + 1))
	printf 'FAIL - %s\n' "$1" >&2
}

assert_eq() {
	if [[ "$1" == "$2" ]]; then ok "$3"; else
		fail "$3"
		printf '       want: %q\n       got:  %q\n' "$1" "$2" >&2
	fi
}

assert_true() {
	if "$@"; then ok "$*"; else fail "$*"; fi
}

assert_false() {
	if "$@"; then fail "NOT $*"; else ok "NOT $*"; fi
}

work="$(mktemp -d "${TMPDIR:-/tmp}/git-release-test.XXXXXX")"
trap 'rm -rf "$work"' EXIT

# --- version validation ---------------------------------------------------

assert_true git_release_version_is_valid 1.2.3
assert_true git_release_version_is_valid 0.0.0
assert_false git_release_version_is_valid v1.2.3
assert_false git_release_version_is_valid 1.2
assert_false git_release_version_is_valid 1.2.3-rc1
# Leading zeros are not semver and would compare surprisingly.
assert_false git_release_version_is_valid 01.2.3

# --- version ordering -----------------------------------------------------

assert_true git_release_version_is_greater 1.0.0 0.9.9
assert_true git_release_version_is_greater 0.25.0 0.24.0
assert_true git_release_version_is_greater 0.0.2 0.0.1
assert_false git_release_version_is_greater 0.24.0 0.25.0
# Equal is not greater: re-releasing the current version must be refused.
assert_false git_release_version_is_greater 1.2.3 1.2.3
# The comparison is numeric, not lexical -- the case that bites string sorts.
assert_true git_release_version_is_greater 0.10.0 0.9.0
assert_true git_release_version_is_greater 0.2.10 0.2.9
assert_false git_release_version_is_greater 0.9.0 0.10.0

# --- bump arithmetic ------------------------------------------------------

assert_eq "1.0.0" "$(git_release_bump_version major 0.24.1)" "major bump zeroes minor and patch"
assert_eq "0.25.0" "$(git_release_bump_version minor 0.24.1)" "minor bump zeroes patch"
assert_eq "0.24.2" "$(git_release_bump_version patch 0.24.1)" "patch bump increments patch"
assert_eq "0.10.0" "$(git_release_bump_version minor 0.9.4)" "minor bump crosses a decimal boundary"

# --- target resolution ----------------------------------------------------

assert_eq "0.25.0" "$(git_release_target_version minor 0.24.0)" "keyword resolves through the bumper"
assert_eq "1.4.0" "$(git_release_target_version 1.4.0 1.3.9)" "an explicit greater version passes through"

# Going backwards must fail rather than quietly produce a bad tag.
if backward="$(git_release_target_version 0.24.0 0.25.0 2>"$work/backward.err")"; then
	fail "target_version refuses a lower version (got $backward)"
else
	ok "target_version refuses a lower version"
	if grep -q 'must be greater than current version' "$work/backward.err"; then
		ok "the refusal names the reason"
	else
		fail "the refusal names the reason"
	fi
fi

# Subshelled deliberately: git_release_die exits, so calling it straight from an
# `if` condition would terminate this script rather than fail one check.
if (git_release_target_version "not-a-version" 1.0.0) >/dev/null 2>&1; then
	fail "target_version rejects a non-version spec"
else
	ok "target_version rejects a non-version spec"
fi

# --- current version discovery --------------------------------------------

mkdir -p "$work/versionfile"
if (
		cd "$work/versionfile" || exit 1
		printf '2.8.1\n' >VERSION
		[[ "$(git_release_current_version)" == "2.8.1" ]]
); then
	ok "current version reads VERSION"
else
	fail "current version reads VERSION"
fi
mkdir -p "$work/noversion"
if (
		cd "$work/noversion" || exit 1
		# No VERSION and no tags: the floor, so a first release can compute a bump.
		[[ "$(git_release_current_version)" == "0.0.0" ]]
); then
	ok "current version falls back to 0.0.0"
else
	fail "current version falls back to 0.0.0"
fi
# --- test runner resolution -----------------------------------------------

mkdir -p "$work/runner"
if (
		cd "$work/runner" || exit 1
		printf 'test:\n\techo hi\n' >Makefile
		[[ "$(git_release_resolve_test_command)" == "make test" ]]
); then
	ok "resolves make test from a Makefile"
else
	fail "resolves make test from a Makefile"
fi
if (
		cd "$work/runner" || exit 1
		mkdir -p tests
		printf '#!/bin/sh\n' >tests/check.sh
		chmod +x tests/check.sh
		# tests/check.sh outranks make test when both exist.
		[[ "$(git_release_resolve_test_command)" == "tests/check.sh" ]]
); then
	ok "tests/check.sh outranks make test"
else
	fail "tests/check.sh outranks make test"
fi
if (
		cd "$work/runner" || exit 1
		[[ "$(GIT_RELEASE_TEST_CMD='custom runner' git_release_resolve_test_command)" == "custom runner" ]]
); then
	ok "GIT_RELEASE_TEST_CMD overrides both"
else
	fail "GIT_RELEASE_TEST_CMD overrides both"
fi
mkdir -p "$work/norunner"
if (
		cd "$work/norunner" || exit 1
		# No runner is empty, not an error: git-release decides what to do.
		[[ -z "$(git_release_resolve_test_command)" ]]
); then
	ok "no runner resolves empty"
else
	fail "no runner resolves empty"
fi
# --- changelog action detection -------------------------------------------

mkdir -p "$work/cl"
if (
		cd "$work/cl" || exit 1
		[[ "$(git_release_changelog_action)" == "create" ]]
); then
	ok "missing CHANGELOG.md means create"
else
	fail "missing CHANGELOG.md means create"
fi
if (
		cd "$work/cl" || exit 1
		printf '# Changelog\n\n## [0.1.0] - 2020-01-01\n' >CHANGELOG.md
		[[ "$(git_release_changelog_action)" == "none" ]]
); then
	ok "no [Unreleased] section means none"
else
	fail "no [Unreleased] section means none"
fi
if (
		cd "$work/cl" || exit 1
		printf '# Changelog\n\n## [Unreleased]\n\n## [0.1.0] - 2020-01-01\n' >CHANGELOG.md
		[[ "$(git_release_changelog_action)" == "promote" ]]
); then
	ok "an [Unreleased] section means promote"
else
	fail "an [Unreleased] section means promote"
fi
# --- unreleased content detection -----------------------------------------

mkdir -p "$work/content"
if (
		cd "$work/content" || exit 1
		printf '## [Unreleased]\n\n## [0.1.0] - 2020-01-01\n\n- shipped\n' >CHANGELOG.md
		! git_release_unreleased_has_content
); then
	ok "an empty [Unreleased] has no content"
else
	fail "an empty [Unreleased] has no content"
fi
if (
		cd "$work/content" || exit 1
		# A heading alone is not content -- "### Added" with nothing under it is
		# the shape left behind by an abandoned edit.
		printf '## [Unreleased]\n\n### Added\n\n## [0.1.0] - 2020-01-01\n' >CHANGELOG.md
		! git_release_unreleased_has_content
); then
	ok "a bare ### heading is not content"
else
	fail "a bare ### heading is not content"
fi
if (
		cd "$work/content" || exit 1
		printf '## [Unreleased]\n\n### Added\n\n- a real entry\n\n## [0.1.0] - 2020-01-01\n' >CHANGELOG.md
		git_release_unreleased_has_content
); then
	ok "an entry under a heading is content"
else
	fail "an entry under a heading is content"
fi
# --- changelog promotion --------------------------------------------------

mkdir -p "$work/promote"
if (
		cd "$work/promote" || exit 1
		cat >CHANGELOG.md <<-'EOF'
	# Changelog

	## [Unreleased]

	### Fixed

	- something real

	## [0.1.0] - 2020-01-01

	[Unreleased]: https://example.com/repo/compare/v0.1.0...HEAD
	[0.1.0]: https://example.com/repo/releases/tag/v0.1.0
	EOF
		git_release_promote_changelog 0.2.0 2026-08-16 v0.2.0 v0.1.0 https://example.com/repo
		grep -q '^## \[Unreleased\]$' CHANGELOG.md &&
			grep -q '^## \[0.2.0\] - 2026-08-16$' CHANGELOG.md &&
			grep -q '^\[Unreleased\]: https://example.com/repo/compare/v0.2.0\.\.\.HEAD$' CHANGELOG.md &&
			grep -q '^\[0.2.0\]: https://example.com/repo/compare/v0.1.0\.\.\.v0.2.0$' CHANGELOG.md &&
			grep -q -- '- something real' CHANGELOG.md
); then
	ok "promote adds the version, keeps [Unreleased], and rewrites links"
else
	fail "promote adds the version, keeps [Unreleased], and rewrites links"
fi
if (
		cd "$work/promote" || exit 1
		# Exactly one [Unreleased] heading must survive, or the next release
		# promotes into a duplicate.
		[[ "$(grep -c '^## \[Unreleased\]$' CHANGELOG.md)" == "1" ]]
); then
	ok "promote leaves exactly one [Unreleased] heading"
else
	fail "promote leaves exactly one [Unreleased] heading"
fi
mkdir -p "$work/firstrelease"
if (
		cd "$work/firstrelease" || exit 1
		printf '# Changelog\n\n## [Unreleased]\n\n- first\n' >CHANGELOG.md
		# No previous tag: the version link must point at the tag itself, since
		# there is nothing to compare against.
		git_release_promote_changelog 0.1.0 2026-08-16 v0.1.0 "" https://example.com/repo
		grep -q '^\[0.1.0\]: https://example.com/repo/releases/tag/v0.1.0$' CHANGELOG.md
); then
	ok "a first release links to the tag, not a comparison"
else
	fail "a first release links to the tag, not a comparison"
fi
# --- changelog creation ---------------------------------------------------

mkdir -p "$work/create"
if (
		cd "$work/create" || exit 1
		git_release_create_changelog 0.1.0 2026-08-16 v0.1.0 "" https://example.com/repo
		grep -q '^## \[Unreleased\]$' CHANGELOG.md &&
			grep -q '^## \[0.1.0\] - 2026-08-16$' CHANGELOG.md &&
			grep -q '^\[0.1.0\]: https://example.com/repo/releases/tag/v0.1.0$' CHANGELOG.md
); then
	ok "create writes a Keep a Changelog skeleton"
else
	fail "create writes a Keep a Changelog skeleton"
fi
# --- summary --------------------------------------------------------------

printf '\n1..%s\n' "$checks"
if ((failures > 0)); then
	printf '# %s of %s checks failed\n' "$failures" "$checks" >&2
	exit 1
fi
printf '# all %s checks passed\n' "$checks"

#!/usr/bin/env bash

set -u -o pipefail

SCRIPT="${GIT_RELEASE_UNDER_TEST:-${HOME}/.local/bin/git-release}"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/git-release-tests.XXXXXX")"
REPO=""
LAST_OUTPUT=""
passes=0
failures=0

cleanup() {
    rm -rf "${TMP_ROOT}"
}
trap cleanup EXIT

fail() {
    echo "not ok - $*" >&2
    return 1
}

assert_eq() {
    local expected="$1" actual="$2" message="$3"
    [[ "${actual}" == "${expected}" ]] || fail "${message}: expected '${expected}', got '${actual}'"
}

assert_contains() {
    local haystack="$1" needle="$2" message="$3"
    [[ "${haystack}" == *"${needle}"* ]] || fail "${message}: missing '${needle}'"
}

assert_not_contains() {
    local haystack="$1" needle="$2" message="$3"
    [[ "${haystack}" != *"${needle}"* ]] || fail "${message}"
}

assert_clean() {
    local status
    status="$(git -C "${REPO}" status --porcelain)"
    assert_eq "" "${status}" "repository should be clean"
}

assert_dirty() {
    local status
    status="$(git -C "${REPO}" status --porcelain)"
    [[ -n "${status}" ]] || fail "repository should retain working-tree changes"
}

assert_index_clean() {
    git -C "${REPO}" diff --cached --quiet || fail "repository index should be clean"
}

assert_tag_absent() {
    local tag="$1"
    [[ -z "$(git -C "${REPO}" tag --list "${tag}")" ]] || fail "tag ${tag} should not exist"
}

new_repo() {
    local name="$1" with_tests="$2" remote="${3:-https://example.com/acme/project.git}"
    REPO="${TMP_ROOT}/${name}"

    git init -q -b main "${REPO}" || return 1
    git -C "${REPO}" config user.name "Git Release Tests"
    git -C "${REPO}" config user.email "git-release-tests@example.com"
    git -C "${REPO}" remote add origin "${remote}"

    printf '1.2.3\n' > "${REPO}/VERSION"
    cat > "${REPO}/CHANGELOG.md" <<'EOF'
# Changelog

## [Unreleased]

### Changed

- Exercise the release helper.

[Unreleased]: https://example.com/acme/project/compare/v1.2.3...HEAD
[1.2.3]: https://example.com/acme/project/releases/tag/v1.2.3
EOF

    if [[ "${with_tests}" == true ]]; then
        mkdir -p "${REPO}/tests"
        cat > "${REPO}/tests/check.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exit 0
EOF
        chmod +x "${REPO}/tests/check.sh"
    fi

    git -C "${REPO}" add -- .
    git -C "${REPO}" commit -qm "Initial fixture"
}

run_release() {
    local rc
    LAST_OUTPUT="$(cd "${REPO}" && "${SCRIPT}" "$@" 2>&1)"
    rc=$?
    return "${rc}"
}

test_success_and_sanitized_remote() {
    local secret="fixture-secret" changelog
    new_repo success true "https://release-user:${secret}@example.com/acme/project.git" || return 1

    run_release patch --no-fetch || fail "release should succeed"
    assert_eq "1.2.4" "$(<"${REPO}/VERSION")" "VERSION should be bumped" || return 1
    assert_eq "v1.2.4" "$(git -C "${REPO}" tag --list 'v1.2.4')" "release tag should exist" || return 1
    changelog="$(<"${REPO}/CHANGELOG.md")"
    assert_contains "${changelog}" "## [1.2.4]" "changelog should contain the release heading" || return 1
    assert_contains "${changelog}" "https://example.com/acme/project/compare/v1.2.4...HEAD" "changelog should use the sanitized URL" || return 1
    assert_not_contains "${changelog}" "${secret}" "changelog leaked remote credentials" || return 1
    assert_not_contains "${LAST_OUTPUT}" "${secret}" "release output leaked remote credentials" || return 1
    assert_clean
}

test_commit_failure_restores_index_and_preserves_tree() {
    local before
    new_repo commit-failure true || return 1
    before="$(git -C "${REPO}" rev-parse HEAD)"
    cat > "${REPO}/.git/hooks/pre-commit" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
    chmod +x "${REPO}/.git/hooks/pre-commit"

    if run_release patch --no-fetch; then
        fail "release should fail when the commit hook fails"
        return 1
    fi
    assert_eq "${before}" "$(git -C "${REPO}" rev-parse HEAD)" "HEAD should be restored" || return 1
    assert_eq "1.2.4" "$(<"${REPO}/VERSION")" "VERSION change should be preserved" || return 1
    assert_contains "${LAST_OUTPUT}" "working-tree changes preserved" "failure should explain preserved changes" || return 1
    assert_tag_absent v1.2.4 || return 1
    assert_index_clean || return 1
    assert_dirty
}

test_release_sync_failure_preserves_tracked_changes() {
    new_repo sync-failure true || return 1
    printf 'original\n' > "${REPO}/SYNCED"
    cat > "${REPO}/.release-sync" <<'EOF'
#!/usr/bin/env bash
printf 'changed\n' > SYNCED
exit 42
EOF
    chmod +x "${REPO}/.release-sync"
    git -C "${REPO}" add -- SYNCED .release-sync
    git -C "${REPO}" commit -qm "Add failing release sync fixture"

    if run_release patch --no-fetch; then
        fail "release should fail when .release-sync fails"
        return 1
    fi
    assert_eq "changed" "$(<"${REPO}/SYNCED")" "release-sync changes should be preserved" || return 1
    assert_eq "1.2.4" "$(<"${REPO}/VERSION")" "VERSION change should be preserved" || return 1
    assert_contains "${LAST_OUTPUT}" "working-tree changes preserved" "failure should explain preserved changes" || return 1
    assert_tag_absent v1.2.4 || return 1
    assert_index_clean || return 1
    assert_dirty
}

test_detached_head_is_always_rejected() {
    local before
    new_repo detached true || return 1
    git -C "${REPO}" checkout -q --detach
    before="$(git -C "${REPO}" rev-parse HEAD)"

    if run_release patch --no-fetch --allow-branch; then
        fail "detached HEAD release should fail even with --allow-branch"
        return 1
    fi
    assert_contains "${LAST_OUTPUT}" "detached HEAD" "failure should explain detached HEAD" || return 1
    assert_eq "${before}" "$(git -C "${REPO}" rev-parse HEAD)" "detached HEAD should remain unchanged" || return 1
    assert_tag_absent v1.2.4 || return 1
    assert_clean
}

test_missing_runner_requires_explicit_override() {
    new_repo no-tests false || return 1

    if run_release patch --no-fetch; then
        fail "release without a test runner should fail"
        return 1
    fi
    assert_contains "${LAST_OUTPUT}" "no test runner detected" "failure should explain the missing runner" || return 1
    assert_tag_absent v1.2.4 || return 1
    assert_clean || return 1

    run_release patch --no-fetch --allow-no-tests || fail "--allow-no-tests should permit the release"
    assert_eq "v1.2.4" "$(git -C "${REPO}" tag --list 'v1.2.4')" "override release tag should exist" || return 1
    assert_contains "${LAST_OUTPUT}" "skipping tests (--allow-no-tests)" "override should be visible in output" || return 1
    assert_clean
}

test_explicit_version_must_increase() {
    new_repo downgrade true || return 1

    if run_release 1.2.2 --no-fetch; then
        fail "release should reject an explicit downgrade"
        return 1
    fi
    assert_contains "${LAST_OUTPUT}" "must be greater than current version 1.2.3" "failure should explain version ordering" || return 1
    assert_tag_absent v1.2.2 || return 1
    assert_clean
}

test_remote_tag_collision_is_rejected() {
    local remote="${TMP_ROOT}/remote-tag.git"
    git init -q --bare "${remote}" || return 1
    git -C "${remote}" symbolic-ref HEAD refs/heads/main
    new_repo remote-tag true "${remote}" || return 1
    git -C "${REPO}" push -q -u origin main || return 1
    git -C "${REPO}" tag -a v1.2.4 -m "Existing remote release"
    git -C "${REPO}" push -q origin refs/tags/v1.2.4 || return 1
    git -C "${REPO}" tag -d v1.2.4 >/dev/null

    if run_release patch; then
        fail "release should reject an existing remote tag"
        return 1
    fi
    assert_contains "${LAST_OUTPUT}" "tag v1.2.4 already exists on origin" "failure should explain remote tag collision" || return 1
    assert_tag_absent v1.2.4 || return 1
    assert_clean
}

test_push_is_atomic_and_exact() {
    local remote="${TMP_ROOT}/atomic-push.git"
    git init -q --bare "${remote}" || return 1
    git -C "${remote}" symbolic-ref HEAD refs/heads/main
    new_repo atomic-push true "${remote}" || return 1
    git -C "${REPO}" push -q -u origin main || return 1
    git -C "${REPO}" tag -a v9.9.9-local-only -m "Unrelated local tag"

    run_release patch --push || fail "release push should succeed"
    assert_eq "$(git -C "${REPO}" rev-parse HEAD)" "$(git -C "${remote}" rev-parse refs/heads/main)" "remote branch should match release commit" || return 1
    assert_eq "$(git -C "${REPO}" rev-parse v1.2.4)" "$(git -C "${remote}" rev-parse refs/tags/v1.2.4)" "remote release tag should match" || return 1
    [[ -z "$(git -C "${remote}" tag --list v9.9.9-local-only)" ]] || fail "unrelated local tag should not be pushed"
}

run_test() {
    local name="$1"
    shift
    if "$@"; then
        echo "ok - ${name}"
        passes=$((passes + 1))
    else
        failures=$((failures + 1))
    fi
}

[[ -x "${SCRIPT}" ]] || {
    echo "git-release test target is not executable: ${SCRIPT}" >&2
    exit 1
}

run_test "successful release sanitizes remote credentials" test_success_and_sanitized_remote
run_test "commit failure cleans index and preserves worktree" test_commit_failure_restores_index_and_preserves_tree
run_test "release-sync failure preserves tracked changes" test_release_sync_failure_preserves_tracked_changes
run_test "detached HEAD is rejected" test_detached_head_is_always_rejected
run_test "missing test runner requires an override" test_missing_runner_requires_explicit_override
run_test "explicit version must increase" test_explicit_version_must_increase
run_test "remote tag collision is rejected" test_remote_tag_collision_is_rejected
run_test "push is atomic and exact" test_push_is_atomic_and_exact

printf '%d passed, %d failed\n' "${passes}" "${failures}"
[[ "${failures}" -eq 0 ]]

#!/usr/bin/env bash

git_release_die() {
	printf 'git-release: %s\n' "$*" >&2
	exit 1
}

git_release_precheck() {
	local dry_run="$1"
	shift
	if [[ "$dry_run" = true ]]; then
		printf 'git-release: note: %s (would block a real release)\n' "$*" >&2
	else
		git_release_die "$*"
	fi
}

git_release_is_transient_network_error() {
	grep -Eiq \
		'could not resolve hostname|temporary failure|operation timed out|connection timed out|connection reset|network is unreachable|failed to connect' \
		"$1"
}

git_release_push_with_retry() {
	local branch="$1" log rc
	log="$(mktemp "${TMPDIR:-/tmp}/git-release-push.XXXXXX")"
	git push origin "$branch" --follow-tags 2>"$log"
	rc=$?
	cat "$log" >&2
	if [[ "$rc" -ne 0 ]] && git_release_is_transient_network_error "$log"; then
		printf '%s\n' 'git-release: push failed with a possible transient network/DNS error; retrying once...' >&2
		sleep 2
		git push origin "$branch" --follow-tags
		rc=$?
	fi
	rm -f "$log"
	return "$rc"
}

git_release_remote_web_url() {
	local remote="$1" scheme rest authority hostpath
	remote="${remote%.git}"
	case "$remote" in
	git@*:*)
		hostpath="${remote#git@}"
		printf 'https://%s/%s\n' "${hostpath%%:*}" "${hostpath#*:}"
		;;
	ssh://*)
		rest="${remote#ssh://}"
		authority="${rest%%/*}"
		[[ "$authority" = *@* ]] && rest="${rest#*@}"
		printf 'https://%s\n' "$rest"
		;;
	http://* | https://*)
		scheme="${remote%%:*}"
		rest="${remote#*://}"
		authority="${rest%%/*}"
		[[ "$authority" = *@* ]] && rest="${rest#*@}"
		printf '%s://%s\n' "$scheme" "$rest"
		;;
	*) printf '%s\n' "$remote" ;;
	esac
}

git_release_resolve_test_command() {
	local configured
	if [[ -n "${GIT_RELEASE_TEST_CMD:-}" ]]; then
		printf '%s\n' "$GIT_RELEASE_TEST_CMD"
	elif configured="$(git config --get release.test-command 2>/dev/null)" && [[ -n "$configured" ]]; then
		printf '%s\n' "$configured"
	elif [[ -x tests/check.sh ]]; then
		printf '%s\n' tests/check.sh
	elif [[ -f Makefile ]] && grep -qE '^test:' Makefile; then
		printf '%s\n' 'make test'
	fi
}

git_release_restore_on_failure() {
	local rc=$?
	trap - EXIT
	rm -f CHANGELOG.md.tmp
	git tag -d "$GIT_RELEASE_TAG" >/dev/null 2>&1 || true
	if git reset -q --mixed "$GIT_RELEASE_ORIGINAL_HEAD"; then
		printf '%s\n' 'git-release: release aborted; HEAD restored and working-tree changes preserved' >&2
	else
		printf '%s\n' 'git-release: release aborted; automatic HEAD restore failed; inspect the repository before continuing' >&2
	fi
	exit "$rc"
}

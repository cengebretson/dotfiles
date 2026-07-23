#!/usr/bin/env bash

git_release_usage() {
	cat <<'EOF'
git-release — cut a release for the current git repository.

Usage:
  git release <version|major|minor|patch> [options]
  git release --current        print the current version and exit

A bump keyword is applied to the current version (minor: 0.5.0 -> 0.6.0);
or pass an explicit X.Y.Z.

Options:
  -n, --dry-run             preview the release without changing anything
  -p, --push                push the branch and tag when done
  --allow-empty-changelog   release even if [Unreleased] has no entries
  --allow-branch            release from a branch other than the default
  --allow-no-tests          release when no test runner can be detected
  --no-fetch                skip the "behind origin" check (no network)
  -c, --current             print the current version and exit
  -h, --help                show this help

Bumps VERSION, promotes the CHANGELOG [Unreleased] section, runs the repo's
tests, commits, and creates an annotated tag vX.Y.Z. Without --push, publish
manually with:

  git push origin <branch> --follow-tags

The current version comes from VERSION or the latest Git tag. The test runner
is resolved from GIT_RELEASE_TEST_CMD, release.test-command, tests/check.sh,
then make test. An executable .release-sync can update other tracked files.
EOF
}

git_release_main() {
	local spec='' dry_run=false show_current=false push=false
	local allow_empty_changelog=false allow_branch=false allow_no_tests=false no_fetch=false
	local arg
	for arg in "$@"; do
		case "$arg" in
		-n | --dry-run) dry_run=true ;;
		-c | --current) show_current=true ;;
		-p | --push) push=true ;;
		--allow-empty-changelog) allow_empty_changelog=true ;;
		--allow-branch) allow_branch=true ;;
		--allow-no-tests) allow_no_tests=true ;;
		--no-fetch) no_fetch=true ;;
		-h | --help)
			git_release_usage
			return
			;;
		-*) git_release_die "unknown option: $arg" ;;
		*)
			[[ -z "$spec" ]] || git_release_die "unexpected argument: $arg"
			spec="$arg"
			;;
		esac
	done

	local root current version tag remote web original_head branch default_branch behind
	local previous_tag date_str old_version test_cmd changelog_action changelog_note push_note
	root="$(git rev-parse --show-toplevel 2>/dev/null)" || git_release_die "not inside a git repository"
	cd "$root" || git_release_die "cannot enter repository root: $root"
	current="$(git_release_current_version)"

	if [[ "$show_current" = true ]]; then
		printf '%s\n' "$current"
		return
	fi
	if ! version="$(git_release_target_version "$spec" "$current")"; then
		git_release_usage >&2
		return 1
	fi
	tag="v$version"

	remote="$(git remote get-url origin 2>/dev/null)" || git_release_die "no 'origin' remote configured"
	web="$(git_release_remote_web_url "$remote")"

	[[ -z "$(git status --porcelain)" ]] || git_release_precheck "$dry_run" "working tree is not clean; commit or stash first"
	original_head="$(git rev-parse --verify HEAD 2>/dev/null || true)"
	[[ -n "$original_head" ]] || git_release_precheck "$dry_run" "repository has no commits"
	if git rev-parse -q --verify "refs/tags/$tag" >/dev/null 2>&1; then
		git_release_precheck "$dry_run" "tag $tag already exists"
	fi

	branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
	default_branch="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##' || true)"
	if [[ -z "$branch" ]]; then
		git_release_precheck "$dry_run" "detached HEAD; checkout a branch first"
	elif [[ "$allow_branch" != true ]]; then
		if [[ -n "$default_branch" && "$branch" != "$default_branch" ]]; then
			git_release_precheck "$dry_run" "on '$branch', not the default branch '$default_branch' (use --allow-branch)"
		elif [[ -z "$default_branch" && "$branch" != main && "$branch" != master ]]; then
			git_release_precheck "$dry_run" "on '$branch', not main/master (use --allow-branch)"
		fi
	fi

	if [[ "$no_fetch" != true && -n "$branch" ]]; then
		if git fetch -q origin "$branch" 2>/dev/null; then
			behind="$(git rev-list --count "HEAD..origin/$branch" 2>/dev/null || echo 0)"
			[[ "$behind" -gt 0 ]] && git_release_precheck "$dry_run" "local $branch is $behind commit(s) behind origin/$branch; pull first"
		else
			printf '%s\n' 'git-release: note: could not fetch origin (offline?); skipping behind-origin check' >&2
		fi
	fi

	previous_tag="$(git describe --tags --abbrev=0 2>/dev/null || true)"
	date_str="$(date +%Y-%m-%d)"
	if [[ -f VERSION ]]; then old_version="$(cat VERSION)"; else old_version='(none)'; fi
	test_cmd="$(git_release_resolve_test_command)"
	if [[ -z "$test_cmd" && "$allow_no_tests" != true ]]; then
		git_release_precheck "$dry_run" "no test runner detected; configure release.test-command or pass --allow-no-tests"
	fi

	changelog_action="$(git_release_changelog_action)"
	changelog_note="$(git_release_changelog_note "$changelog_action" "$version" "$date_str")"
	if [[ "$changelog_action" = promote ]] && ! git_release_unreleased_has_content; then
		if [[ "$allow_empty_changelog" = true ]]; then
			changelog_note="$changelog_note (WARNING: [Unreleased] is empty)"
		elif [[ "$dry_run" = true ]]; then
			changelog_note="$changelog_note (EMPTY — would block; pass --allow-empty-changelog)"
		else
			git_release_die "[Unreleased] in CHANGELOG.md has no entries; add notes or pass --allow-empty-changelog"
		fi
	fi
	if [[ "$push" = true ]]; then push_note='and push to origin'; else push_note='(no push)'; fi

	if [[ "$dry_run" = true ]]; then
		cat <<EOF
[dry-run] repo:         ${web}
[dry-run] new version:  ${version}  (tag ${tag})
[dry-run] previous tag: ${previous_tag:-(none)}
[dry-run] test runner:  ${test_cmd:-(none detected)}
[dry-run] VERSION:      ${old_version} -> ${version}
[dry-run] CHANGELOG:    ${changelog_note}
[dry-run] would run tests, commit VERSION/CHANGELOG, tag ${tag} ${push_note}
EOF
		return
	fi

	if [[ -n "$test_cmd" ]]; then
		printf 'Running tests: %s\n' "$test_cmd"
		bash -c "$test_cmd"
	else
		printf '%s\n' 'git-release: no test runner detected; skipping tests (--allow-no-tests)' >&2
	fi

	# Used by the EXIT trap helper sourced from common.sh.
	# shellcheck disable=SC2034
	GIT_RELEASE_TAG=$tag
	# shellcheck disable=SC2034
	GIT_RELEASE_ORIGINAL_HEAD=$original_head
	trap git_release_restore_on_failure EXIT

	printf '%s\n' "$version" >VERSION
	git_release_write_changelog "$changelog_action" "$version" "$date_str" "$tag" "$previous_tag" "$web"
	if [[ -x ./.release-sync ]]; then
		printf 'Running after-bump hook: .release-sync %s\n' "$version"
		./.release-sync "$version"
	fi

	local release_tracked_paths=() path
	while IFS= read -r -d '' path; do
		release_tracked_paths+=("$path")
	done < <(git diff --name-only -z)
	git add -- VERSION
	[[ -f CHANGELOG.md ]] && git add -- CHANGELOG.md
	[[ "${#release_tracked_paths[@]}" -eq 0 ]] || git add -- "${release_tracked_paths[@]}"

	git diff --quiet || git_release_die "tracked files changed while preparing the release; changes were preserved"
	git commit -m "Release $tag"
	git diff --quiet || git_release_die "tracked files changed during the release commit; changes were preserved"
	git tag -a "$tag" -m "$tag"
	trap - EXIT

	printf 'Tagged %s.\n' "$tag"
	if [[ "$push" = true ]]; then
		printf 'Pushing %s and %s to origin...\n' "$branch" "$tag"
		git_release_push_with_retry "$branch" ||
			git_release_die "push failed; the release commit and tag $tag exist locally — retry with: git push origin $branch --follow-tags"
		printf 'Pushed %s; the release workflow will publish it.\n' "$tag"
		printf '  Actions: %s/actions\n  Release: %s/releases/tag/%s\n' "$web" "$web" "$tag"
	else
		printf '\nReview the commit and changelog, then publish with:\n\n  git push origin %s --follow-tags\n\n' "$branch"
	fi
}

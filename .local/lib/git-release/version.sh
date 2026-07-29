#!/usr/bin/env bash

git_release_current_version() {
	if [[ -f VERSION ]]; then
		cat VERSION
	else
		local tag
		tag="$(git describe --tags --abbrev=0 2>/dev/null || true)"
		if [[ -n "$tag" ]]; then printf '%s\n' "${tag#v}"; else printf '%s\n' 0.0.0; fi
	fi
}

git_release_bump_version() {
	local kind="$1" current="$2" major minor patch
	git_release_version_is_valid "$current" ||
		git_release_die "current version '$current' is not X.Y.Z; pass an explicit version instead"
	IFS=. read -r major minor patch <<<"$current"
	case "$kind" in
	major)
		major=$((major + 1))
		minor=0
		patch=0
		;;
	minor)
		minor=$((minor + 1))
		patch=0
		;;
	patch) patch=$((patch + 1)) ;;
	esac
	printf '%s.%s.%s\n' "$major" "$minor" "$patch"
}

git_release_version_is_valid() {
	[[ "$1" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]
}

git_release_version_is_greater() {
	local candidate="$1" current="$2"
	local candidate_major candidate_minor candidate_patch
	local current_major current_minor current_patch

	IFS=. read -r candidate_major candidate_minor candidate_patch <<<"$candidate"
	IFS=. read -r current_major current_minor current_patch <<<"$current"

	((10#$candidate_major > 10#$current_major)) && return 0
	((10#$candidate_major < 10#$current_major)) && return 1
	((10#$candidate_minor > 10#$current_minor)) && return 0
	((10#$candidate_minor < 10#$current_minor)) && return 1
	((10#$candidate_patch > 10#$current_patch))
}

git_release_target_version() {
	local spec="$1" current="$2"
	case "$spec" in
	major | minor | patch) git_release_bump_version "$spec" "$current" ;;
	'') return 2 ;;
	*)
		git_release_version_is_valid "$spec" ||
			git_release_die "not a version or bump keyword: $spec (use X.Y.Z, or major|minor|patch)"
		if git_release_version_is_valid "$current" && ! git_release_version_is_greater "$spec" "$current"; then
			git_release_die "target version $spec must be greater than current version $current"
		fi
		printf '%s\n' "$spec"
		;;
	esac
}

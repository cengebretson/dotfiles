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
	[[ "$current" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
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

git_release_target_version() {
	local spec="$1" current="$2"
	case "$spec" in
	major | minor | patch) git_release_bump_version "$spec" "$current" ;;
	'') return 2 ;;
	*)
		[[ "$spec" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
			git_release_die "not a version or bump keyword: $spec (use X.Y.Z, or major|minor|patch)"
		printf '%s\n' "$spec"
		;;
	esac
}

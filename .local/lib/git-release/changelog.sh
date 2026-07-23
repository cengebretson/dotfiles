#!/usr/bin/env bash

git_release_unreleased_has_content() {
	awk '
    /^## \[Unreleased\]/ { inblock = 1; next }
    inblock && (/^## \[/ || /^\[Unreleased\]:/) { inblock = 0 }
    inblock && NF && !/^###/ { found = 1 }
    END { exit found ? 0 : 1 }
  ' CHANGELOG.md
}

git_release_changelog_action() {
	if [[ -f CHANGELOG.md ]] && grep -qE '^## \[Unreleased\]' CHANGELOG.md; then
		printf '%s\n' promote
	elif [[ -f CHANGELOG.md ]]; then
		printf '%s\n' none
	else
		printf '%s\n' create
	fi
}

git_release_changelog_note() {
	local action="$1" version="$2" date_str="$3"
	case "$action" in
	promote) printf 'promote [Unreleased] -> [%s] - %s\n' "$version" "$date_str" ;;
	create) printf 'create CHANGELOG.md with a [%s] - %s section\n' "$version" "$date_str" ;;
	none) printf '%s\n' 'CHANGELOG.md has no [Unreleased] section — leaving it untouched' ;;
	esac
}

git_release_promote_changelog() {
	local version="$1" date_str="$2" tag="$3" previous_tag="$4" web="$5"
	awk -v ver="$version" -v d="$date_str" -v tag="$tag" -v prev="$previous_tag" -v web="$web" '
    function link_refs() {
      print "[Unreleased]: " web "/compare/" tag "...HEAD"
      if (prev != "")
        print "[" ver "]: " web "/compare/" prev "..." tag
      else
        print "[" ver "]: " web "/releases/tag/" tag
    }
    /^## \[Unreleased\]/ && !promoted {
      print
      print ""
      print "## [" ver "] - " d
      promoted = 1
      next
    }
    /^\[Unreleased\]:/ {
      link_refs()
      linked = 1
      next
    }
    { print }
    END {
      if (!linked) {
        print ""
        link_refs()
      }
    }
  ' CHANGELOG.md >CHANGELOG.md.tmp
	mv CHANGELOG.md.tmp CHANGELOG.md
}

git_release_create_changelog() {
	local version="$1" date_str="$2" tag="$3" previous_tag="$4" web="$5"
	{
		cat <<EOF
# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [${version}] - ${date_str}

EOF
		printf '[Unreleased]: %s/compare/%s...HEAD\n' "$web" "$tag"
		if [[ -n "$previous_tag" ]]; then
			printf '[%s]: %s/compare/%s...%s\n' "$version" "$web" "$previous_tag" "$tag"
		else
			printf '[%s]: %s/releases/tag/%s\n' "$version" "$web" "$tag"
		fi
	} >CHANGELOG.md
}

git_release_write_changelog() {
	local action="$1"
	shift
	case "$action" in
	promote) git_release_promote_changelog "$@" ;;
	create) git_release_create_changelog "$@" ;;
	none) return 0 ;;
	esac
}

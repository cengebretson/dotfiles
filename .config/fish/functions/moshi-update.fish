function moshi-update --description 'Upgrade moshi-hook through Homebrew using a downloaded archive'
    argparse h/help s/skip-update 'a/archive=' -- $argv
    or return 2

    if set -q _flag_help
        _moshi_update_help
        return 0
    end

    if test (count $argv) -gt 1
        echo 'moshi-update: expected at most one archive path' >&2
        _moshi_update_help >&2
        return 2
    end
    if set -q _flag_archive; and test (count $argv) -eq 1
        echo 'moshi-update: pass the archive either positionally or with --archive, not both' >&2
        return 2
    end

    set -l archive
    if set -q _flag_archive
        set archive $_flag_archive
    else if test (count $argv) -eq 1
        set archive $argv[1]
    end

    for dependency in brew jq shasum
        if not command -q $dependency
            printf 'moshi-update: required command not found: %s\n' $dependency >&2
            return 1
        end
    end

    set -l formula rjyo/moshi/moshi-hook

    if not set -q _flag_skip_update
        echo '==> Refreshing Homebrew metadata'
        brew update
        or return $status
    end

    echo '==> Reading the current Moshi formula'
    set -l metadata (brew info --json=v2 $formula)
    or return $status

    set -l target_version (printf '%s\n' "$metadata" | jq -r '.formulae[0].versions.stable // empty')
    set -l installed_version (printf '%s\n' "$metadata" | jq -r '.formulae[0].installed[-1].version // "not installed"')
    set -l url (printf '%s\n' "$metadata" | jq -r '.formulae[0].urls.stable.url // empty')
    set -l expected_sha (printf '%s\n' "$metadata" | jq -r '.formulae[0].urls.stable.checksum // empty')

    if test -z "$target_version" -o -z "$url" -o -z "$expected_sha"
        echo 'moshi-update: Homebrew returned incomplete Moshi formula metadata' >&2
        return 1
    end

    printf '    installed: %s\n' $installed_version
    printf '    available: %s\n' $target_version

    if test "$installed_version" = "$target_version"
        echo '✓ moshi-hook is already current'
        return 0
    end

    set -l filename (string split -r -m 1 / -- $url)[-1]
    set -l download_directory "$HOME/Downloads"
    set -l download_path "$download_directory/$filename"
    if test -z "$archive"
        set archive "$download_path"
    end
    set -l cache_path (brew --cache $formula)
    or return $status

    set -l cache_verified 0
    if test -f "$cache_path"
        set -l cached_sha (_moshi_update_sha256 "$cache_path")
        if test "$cached_sha" = "$expected_sha"
            set archive "$cache_path"
            set cache_verified 1
            echo '✓ Homebrew cache already contains the verified archive'
        else
            echo 'moshi-update: ignoring an invalid cached archive' >&2
        end
    end

    if not test -f "$archive"
        printf 'moshi-update: archive not found: %s\n' "$archive" >&2
        printf 'Download it from:\n  %s\n' "$url" >&2
        return 1
    end

    if test $cache_verified -eq 0
        echo '==> Verifying the downloaded archive'
        set -l actual_sha (_moshi_update_sha256 "$archive")
        if test "$actual_sha" != "$expected_sha"
            printf 'moshi-update: checksum mismatch\n  expected: %s\n  actual:   %s\n' "$expected_sha" "$actual_sha" >&2
            return 1
        end
        echo '✓ checksum matches the Homebrew formula'

        set -l cache_directory (dirname "$cache_path")
        mkdir -p "$cache_directory"
        or return $status
        cp "$archive" "$cache_path"
        or return $status
        echo '✓ seeded the Homebrew download cache'
    end

    echo '==> Upgrading moshi-hook'
    brew upgrade $formula
    or return $status

    echo '==> Restarting moshi-hook'
    # Homebrew services refuses to run while TMUX is exported.
    env -u TMUX brew services restart $formula
    or return $status

    echo '==> Verifying moshi-hook'
    set -l verified_metadata (brew info --json=v2 $formula)
    or return $status
    set -l verified_version (printf '%s\n' "$verified_metadata" | jq -r '.formulae[0].installed[-1].version // empty')

    set -l services (env -u TMUX brew services list --json)
    or return $status
    set -l service_status (printf '%s\n' "$services" | jq -r '.[] | select(.name == "moshi-hook") | .status')

    if test "$verified_version" != "$target_version"
        printf 'moshi-update: expected version %s but Homebrew reports %s\n' "$target_version" "$verified_version" >&2
        return 1
    end
    if test "$service_status" != started
        printf 'moshi-update: moshi-hook service is not started (status: %s)\n' "$service_status" >&2
        return 1
    end

    printf '✓ moshi-hook %s is installed and the service is started\n' "$verified_version"

    if functions -q __moshi_refresh_paired
        __moshi_refresh_paired
    end
    tmux refresh-client -S 2>/dev/null

    return 0
end

function _moshi_update_sha256 --argument-names archive
    set -l checksum_line (shasum -a 256 "$archive")
    or return $status
    string match -r '^[0-9a-f]+' -- "$checksum_line"
end

function _moshi_update_help
    echo 'Usage:'
    echo '  moshi-update [ARCHIVE]'
    echo '  moshi-update --archive ARCHIVE'
    echo ''
    echo 'Refresh the Moshi Homebrew formula, use its archive from ~/Downloads by default, verify its'
    echo 'formula checksum, seed Homebrew\'s cache, upgrade, restart, and verify the service.'
    echo ''
    echo 'Options:'
    echo '  -a, --archive PATH  Override the default archive in ~/Downloads'
    echo '  -s, --skip-update   Skip brew update and use the currently tapped formula'
    echo '  -h, --help          Show this help'
end

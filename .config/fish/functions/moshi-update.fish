function moshi-update --description 'Upgrade moshi-hook through Homebrew when its CDN blocks curl'
    argparse h/help n/no-open s/skip-update 'a/archive=' -- $argv
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

    for dependency in brew jq shasum osascript
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
    set -l cache_path (brew --cache $formula)
    or return $status

    if test -f "$cache_path"
        set -l cached_sha (_moshi_update_sha256 "$cache_path")
        if test "$cached_sha" = "$expected_sha"
            set archive "$cache_path"
            echo '✓ Homebrew cache already contains the verified archive'
        else
            echo 'moshi-update: ignoring an invalid cached archive' >&2
        end
    end

    if test -z "$archive"
        set archive (_moshi_update_find_download "$download_directory" "$filename" "$expected_sha")
        if test -n "$archive"
            echo '✓ Found a verified archive in Downloads'
        end
    end

    if test -z "$archive"
        echo ''
        printf 'Homebrew cannot fetch this CDN URL with curl:\n  %s\n' "$url"
        printf 'Expected SHA-256:\n  %s\n' "$expected_sha"

        if set -q _flag_no_open
            printf 'Download it in a browser, then run:\n  moshi-update --archive %s\n' "$download_path" >&2
            return 2
        end

        echo '==> Downloading the artifact with Google Chrome'
        osascript \
            -e 'on run argv' \
            -e 'tell application "Google Chrome" to open location (item 1 of argv)' \
            -e 'end run' \
            "$url"
        or begin
            echo 'moshi-update: Google Chrome could not be opened' >&2
            return 1
        end

        echo '    waiting up to 5 minutes for Chrome to finish the download'
        set archive (_moshi_update_wait_for_download "$download_directory" "$filename" "$expected_sha" 300)
        or return $status
        printf '✓ Chrome download completed: %s\n' "$archive"
    end

    if not test -f "$archive"
        printf 'moshi-update: archive not found: %s\n' "$archive" >&2
        return 1
    end

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

function _moshi_update_find_download --argument-names download_directory filename expected_sha
    set -l filename_prefix (string replace -r '\.tar\.gz$' '' -- "$filename")
    set -l candidates (find "$download_directory" -maxdepth 1 -type f -name "$filename_prefix*.tar.gz" -print 2>/dev/null)

    for candidate in $candidates
        set -l candidate_sha (_moshi_update_sha256 "$candidate")
        if test "$candidate_sha" = "$expected_sha"
            echo "$candidate"
            return 0
        end
    end

    return 1
end

function _moshi_update_wait_for_download --argument-names download_directory filename expected_sha timeout_seconds
    set -l elapsed 0

    while test $elapsed -lt $timeout_seconds
        set -l archive (_moshi_update_find_download "$download_directory" "$filename" "$expected_sha")
        if test -n "$archive"
            echo "$archive"
            return 0
        end

        sleep 1
        set elapsed (math $elapsed + 1)
    end

    printf 'moshi-update: timed out waiting for Chrome to download %s\n' "$filename" >&2
    return 1
end

function _moshi_update_help
    echo 'Usage:'
    echo '  moshi-update [ARCHIVE]'
    echo '  moshi-update --archive ARCHIVE'
    echo ''
    echo 'Refresh the Moshi Homebrew formula, download the current artifact with Chrome when needed,'
    echo 'verify its formula checksum, seed Homebrew\'s cache, upgrade, restart, and verify the service.'
    echo ''
    echo 'Options:'
    echo '  -a, --archive PATH  Use an already-downloaded tarball'
    echo '  -n, --no-open       Do not open the browser; print the required artifact instead'
    echo '  -s, --skip-update   Skip brew update and use the currently tapped formula'
    echo '  -h, --help          Show this help'
end

function _coral_cache_file
    set -f remote_url (git remote get-url origin 2>/dev/null)
    test -n "$remote_url"; or return 1

    set -f repo_key (printf '%s' "$remote_url" | shasum -a 256 2>/dev/null | string sub -l 16)
    test -n "$repo_key"; or return 1

    set -f cache_dir (_coral_cache_dir)
    mkdir -p "$cache_dir" 2>/dev/null
    or return 1

    printf '%s/%s.cache\n' "$cache_dir" "$repo_key"
end

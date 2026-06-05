function _coral_cache_dir
    set -f cache_home "$HOME/.cache"
    if set -q XDG_CACHE_HOME; and test -n "$XDG_CACHE_HOME"
        set cache_home "$XDG_CACHE_HOME"
    end

    printf '%s/coral/pr\n' "$cache_home"
end

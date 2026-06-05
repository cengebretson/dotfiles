function _coral_clear_cache
    set -f cache_file (_coral_cache_file); or return 0
    rm -f "$cache_file"
end

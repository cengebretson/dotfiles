function _coral_cache_ttl
    if set -q CORAL_CACHE_TTL; and string match -qr '^[0-9]+$' -- $CORAL_CACHE_TTL; and test $CORAL_CACHE_TTL -gt 0
        printf '%s\n' "$CORAL_CACHE_TTL"
    else
        printf '300\n'
    end
end

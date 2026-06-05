function _coral_since_date --argument-names days
    test -n "$days"; or return 1
    test "$days" -gt 0; or return 1

    set -f since (date -v-"$days"d +%F 2>/dev/null)
    if test -z "$since"
        set since (date -d "$days days ago" +%F 2>/dev/null)
    end

    test -n "$since"; or return 1
    printf '%s\n' "$since"
end

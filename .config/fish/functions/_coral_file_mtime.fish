function _coral_file_mtime --argument-names path
    test -n "$path"; or return 1

    set -f mtime (stat -f %m "$path" 2>/dev/null)
    if test -z "$mtime"
        set mtime (stat -c %Y "$path" 2>/dev/null)
    end

    test -n "$mtime"; or return 1
    printf '%s\n' "$mtime"
end

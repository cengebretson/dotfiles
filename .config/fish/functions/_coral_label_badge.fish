function _coral_label_badge --argument-names label
    test -n "$label"; or return 0

    set -f fg '1e1e2e'
    set -f bg 'fab387'
    printf '%s %s %s' (set_color $fg --background $bg) "$label" (set_color normal)
end

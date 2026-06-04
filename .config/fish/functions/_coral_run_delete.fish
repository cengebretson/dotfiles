function _coral_run_delete --argument-names branch force fzf_port
    set -f w (math "max(56, "(string length $branch)" + 22)")
    if test "$force" = force
        _coral_popup "_coral_delete_common $branch force" " Force Delete " $fzf_port $w 8
    else
        _coral_popup "_coral_delete_common $branch" " Delete Branch " $fzf_port $w 8
    end
end

function _coral_run_rebase --argument branch fzf_port
    set -f esc (string escape -- $branch)
    _coral_popup "_coral_rebase $esc" " Rebase Branch " $fzf_port "80%" 22
end

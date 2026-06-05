function _coral_pr_history_days
    if set -q CORAL_PR_HISTORY_DAYS; and string match -qr '^[0-9]+$' -- $CORAL_PR_HISTORY_DAYS
        printf '%s\n' "$CORAL_PR_HISTORY_DAYS"
    else
        printf '30\n'
    end
end

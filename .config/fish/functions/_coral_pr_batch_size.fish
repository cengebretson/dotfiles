function _coral_pr_batch_size
    if set -q CORAL_PR_BATCH_SIZE; and string match -qr '^[0-9]+$' -- $CORAL_PR_BATCH_SIZE; and test $CORAL_PR_BATCH_SIZE -gt 0
        printf '%s\n' "$CORAL_PR_BATCH_SIZE"
    else
        printf '10\n'
    end
end

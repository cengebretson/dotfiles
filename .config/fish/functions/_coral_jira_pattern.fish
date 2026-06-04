function _coral_jira_pattern
    if set -q CORAL_JIRA_KEY_PATTERN
        echo $CORAL_JIRA_KEY_PATTERN
    else
        echo '[A-Z]+-[0-9]+'
    end
end

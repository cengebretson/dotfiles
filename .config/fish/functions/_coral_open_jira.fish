function _coral_open_jira --argument-names branch
    if not set -q CORAL_JIRA_DOMAIN
        echo "coral: CORAL_JIRA_DOMAIN is not set" >&2
        return 1
    end

    set -f key (string match -r (_coral_jira_pattern) "$branch")
    if test -n "$key"
        open "https://$CORAL_JIRA_DOMAIN/browse/$key" 2>/dev/null
        or echo "coral: could not open browser" >&2
    else
        echo "coral: no Jira key found in branch: $branch" >&2
    end
end

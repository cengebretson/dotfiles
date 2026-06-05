function _coral_open_jira --argument-names branch
    _coral_load_config

    set -f key (string match -r (_coral_jira_pattern) "$branch")
    if test -z "$key"
        echo "coral: no Jira key found in branch: $branch" >&2
        return 1
    end

    set -f url (_coral_jira_url "$key")
    if test -z "$url"
        echo "coral: CORAL_JIRA_URL_TEMPLATE is not set" >&2
        return 1
    end

    open "$url" 2>/dev/null
    or echo "coral: could not open browser" >&2
end

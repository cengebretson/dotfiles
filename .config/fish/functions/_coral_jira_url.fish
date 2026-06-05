function _coral_jira_url --argument-names key
    _coral_load_config

    test -n "$key"; or return 1
    set -q CORAL_JIRA_URL_TEMPLATE; and test -n "$CORAL_JIRA_URL_TEMPLATE"; or return 1

    string replace --all '{key}' "$key" "$CORAL_JIRA_URL_TEMPLATE"
end

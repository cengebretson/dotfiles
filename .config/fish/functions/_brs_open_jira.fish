function _brs_open_jira --argument branch
    set -f key (string match -r '(?:DLOS|LOSIMP|FLYWL|YELHAM)-[0-9]+' $branch)
    if test -n "$key"
        open "https://venturesgo.atlassian.net/browse/$key"
    else
        echo "brs: no Jira key found in branch: $branch" >&2
    end
end

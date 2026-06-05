source (dirname (status --current-filename))/helpers.fish

set temp_config_home (mktemp -d)
set temp_cache_home (mktemp -d)
set -gx XDG_CONFIG_HOME $temp_config_home
set -gx XDG_CACHE_HOME $temp_cache_home

coral_test_reset
@test "config file uses XDG_CONFIG_HOME" (_coral_config_file) = "$temp_config_home/coral/config.fish"
@test "cache dir uses XDG_CACHE_HOME" (_coral_cache_dir) = "$temp_cache_home/coral/pr"

mkdir -p "$temp_config_home/coral"
printf '%s\n' \
    "set -g CORAL_JIRA_URL_TEMPLATE 'https://jira.example.com/browse/{key}'" \
    "set -g CORAL_PR_BATCH_SIZE 7" \
    "set -g CORAL_PR_HISTORY_DAYS 0" \
    > "$temp_config_home/coral/config.fish"

coral_test_reset
_coral_load_config

@test "config file sets Jira template" (_coral_jira_url FLYWL-634) = "https://jira.example.com/browse/FLYWL-634"
@test "config file sets PR batch size" (_coral_pr_batch_size) = 7
@test "config file sets PR history days" (_coral_pr_history_days) = 0
@test "config defaults missing cache TTL" (_coral_cache_ttl) = 300
@test "config defaults Jira key pattern" (_coral_jira_pattern) = "[A-Z]+-[0-9]+"

rm -rf "$temp_config_home" "$temp_cache_home"

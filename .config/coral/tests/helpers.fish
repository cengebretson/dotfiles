set -g CORAL_TEST_ROOT (dirname (status --current-filename))/../..
set -g CORAL_FUNCTIONS_DIR "$HOME/.config/fish/functions"

for file in $CORAL_FUNCTIONS_DIR/coral.fish $CORAL_FUNCTIONS_DIR/_coral*.fish
    source $file
end

function coral_test_reset
    set -e __coral_config_loaded
    set -e __coral_config_explicit
    set -e CORAL_BASE_BRANCHES
    set -e CORAL_CACHE_TTL
    set -e CORAL_COLOR_ACCENT
    set -e CORAL_COLOR_BG
    set -e CORAL_COLOR_DANGER
    set -e CORAL_COLOR_MUTED
    set -e CORAL_COLOR_TEXT
    set -e CORAL_JIRA_KEY_PATTERN
    set -e CORAL_JIRA_URL_TEMPLATE
    set -e CORAL_PR_BATCH_SIZE
    set -e CORAL_PR_HISTORY_DAYS
end

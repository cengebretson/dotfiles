# Shim for the non-tmux fzf bind path in coral.fish:
#   'alt-d:execute(_coral_delete_branch {1})+reload(_coral_list)'
# Named wrapper needed because fzf execute() parses the command by whitespace —
# passing '_coral_delete_common {1}' with a flag argument breaks outside tmux.
function _coral_delete_branch --argument-names branch
    _coral_delete_common "$branch"
end

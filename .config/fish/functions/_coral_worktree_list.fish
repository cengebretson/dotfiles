function _coral_worktree_list
    # Outputs "refs/heads/<branch>\t<path>" for each LINKED worktree.
    # Skips the first block (main worktree = current checkout).
    git worktree list --porcelain 2>/dev/null \
        | awk '
            /^worktree / { n++; path = substr($0, 10); branch = "" }
            /^branch /   { branch = $2 }
            /^$/         { if (n > 1 && branch != "") print branch "\t" path }
            END          { if (n > 1 && branch != "") print branch "\t" path }
        '
end

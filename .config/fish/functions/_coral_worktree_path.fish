function _coral_worktree_path --argument-names branch
    # Skip the first block (main worktree) — only linked worktrees get a path shown.
    git worktree list --porcelain 2>/dev/null \
        | awk -v b="refs/heads/$branch" '
            /^worktree / { n++; path = $2 }
            n > 1 && $0 == "branch " b { print path }
        '
end

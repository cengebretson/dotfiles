function _coral_worktree_path --argument-names branch
    _coral_worktree_list | awk -F'\t' -v b="refs/heads/$branch" '$1 == b {print $2; exit}'
end

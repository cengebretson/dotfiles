function _coral_rebase --argument-names branch
    # Use the PR target branch if one exists — it's the exact right base.
    # Fall back to the inferred upstream for branches without a PR.
    set -f pr_base (gh pr view "$branch" --json baseRefName --jq '.baseRefName' 2>/dev/null)
    if test -n "$pr_base"
        set -f upstream "origin/$pr_base"
    else
        set -f upstream (_coral_upstream "$branch"); or return 1
    end

    # Extract remote and remote branch from upstream (e.g. origin/develop → origin, develop)
    set -f remote (string split / $upstream)[1]
    set -f remote_branch (string join / (string split / $upstream)[2..])

    set -f original (git branch --show-current 2>/dev/null)
    if test -z "$original"
        echo "coral: cannot rebase from a detached HEAD state" >&2
        return 1
    end

    # Confirm intent before doing anything
    _coral_confirm "Rebase '$branch' onto '$upstream'?"; or return 0

    # Check for uncommitted changes before any git operation — guards both the current-branch
    # rebase case and the checkout-then-rebase case.
    git diff --quiet 2>/dev/null
    and git diff --cached --quiet 2>/dev/null
    or begin
        echo "coral: '$original' has uncommitted changes — commit or stash them first" >&2
        return 1
    end

    echo "Fetching $upstream..."
    git fetch "$remote" "$remote_branch"
    or return 1

    if test "$branch" != "$original"
        echo "Checking out $branch..."
        git checkout "$branch"
        or begin
            echo "ERROR: checkout failed" >&2
            return 1
        end
    end

    echo "Rebasing $branch onto $upstream..."
    echo ""
    git rebase "$upstream" 2>&1
    or begin
        echo ""
        echo "ERROR: rebase had conflicts — aborting and restoring $branch" >&2
        git rebase --abort 2>&1
        if test "$branch" != "$original"
            git checkout "$original"
            or echo "ERROR: could not restore branch '$original' — you may need to checkout manually" >&2
        end
        return 1
    end

    echo ""
    echo "Done. $branch is up to date with $upstream."
    echo ""
    if _coral_confirm "Force push '$branch' to origin?"
        echo "Force pushing..."
        git push --force-with-lease origin "$branch" 2>&1
        and echo "Done."
        or echo "ERROR: force push failed" >&2
    end

end

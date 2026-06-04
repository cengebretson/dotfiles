function _coral_upstream --argument-names branch
    set -f tracking (git rev-parse --abbrev-ref "$branch@{upstream}" 2>/dev/null)
    # Only trust tracking if it points to a true base, not the branch's own remote counterpart.
    if test -n "$tracking" -a "$tracking" != "origin/$branch"
        printf '%s\n' $tracking
        return 0
    end

    # Infer the parent branch: find which remote base branch has the most recent
    # common ancestor (merge-base) with this branch. The most recent merge-base
    # timestamp means we forked from that branch most recently.
    # Exclude feature/bugfix/chore siblings — only base-like branches are candidates.
    set -f candidates (git for-each-ref --format='%(refname:short)' refs/remotes/origin/ 2>/dev/null \
        | grep -vE '(HEAD|/feature/|/bugfix/|/chore/|/fix/)' \
        | grep -v "origin/$branch")

    set -f best_ref
    set -f best_date 0
    for ref in $candidates
        set -f mb (git merge-base "$branch" "$ref" 2>/dev/null)
        test -z "$mb"; and continue
        set -f date (git log -1 --format='%ct' "$mb" 2>/dev/null)
        test -z "$date"; and continue
        if test "$date" -gt "$best_date"
            set best_date $date
            set best_ref $ref
        end
    end

    if test -n "$best_ref"
        printf '%s\n' $best_ref
        return 0
    end

    set -f base (_coral_base_branch); or return 1
    printf '%s\n' "origin/$base"
end

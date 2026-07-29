function updates --description 'Update selected Homebrew, tmux, Fisher, Fish, and mise tooling'
    argparse h/help n/dry-run 'o/only=' -- $argv
    or return 2

    if set -q _flag_help
        _updates_help
        return 0
    end
    if test (count $argv) -gt 0
        printf 'updates: unexpected argument: %s\n' "$argv[1]" >&2
        _updates_help >&2
        return 2
    end

    set -l known_components brew bundle tmux fisher completions mise cleanup
    set -l only
    if set -q _flag_only
        set only (string split ',' -- $_flag_only)
    end
    for component in $only
        if not contains -- "$component" $known_components
            printf 'updates: unknown component for --only: %s\n' "$component" >&2
            printf 'updates: choose from: %s\n' (string join ', ' $known_components) >&2
            return 2
        end
    end

    set -l dry_run 0
    set -q _flag_dry_run; and set dry_run 1
    set -l failures
    set -l results
    set -l tpm_update "$HOME/.config/tmux/plugins/tpm/bin/update_plugins"
    set -l brewfile "$HOME/.config/Brewfile"
    set -l ok (set_color green)'✓'(set_color normal)
    set -l fail (set_color red)'✗'(set_color normal)
    set -l pass_mark $ok
    test $dry_run -eq 1; and set pass_mark '·'

    if _updates_selected brew $only
        if _updates_run $dry_run 'brew update' brew update
            set --append results "$pass_mark brew update"
        else
            set --append results "$fail brew update"
            set --append failures 'brew update'
        end

        if _updates_run $dry_run 'brew upgrade' brew upgrade
            set --append results "$pass_mark brew upgrade"
        else
            set --append results "$fail brew upgrade"
            set --append failures 'brew upgrade'
        end
    end

    if _updates_selected bundle $only
        if test -f "$brewfile"
            if _updates_run $dry_run 'brew bundle install (missing from Brewfile)' brew bundle install --file="$brewfile" --no-upgrade
                set --append results "$pass_mark brew bundle install"
            else
                set --append results "$fail brew bundle install"
                set --append failures 'brew bundle install'
            end
        else
            printf '\n==> brew bundle install (missing from Brewfile)\n'
            echo "updates: skipping brew bundle; $brewfile not found" >&2
            set --append results '- brew bundle skipped'
        end
    end

    if _updates_selected tmux $only
        if test -x "$tpm_update"
            if _updates_run $dry_run 'tmux TPM plugins' "$tpm_update" all
                set --append results "$pass_mark tmux TPM plugins"
            else
                set --append results "$fail tmux TPM plugins"
                set --append failures 'tmux TPM plugins'
            end
        else
            printf '\n==> tmux TPM plugins\n'
            echo "updates: skipping tmux TPM plugins; $tpm_update is not executable" >&2
            set --append results '- tmux TPM plugins skipped'
        end
    end

    if _updates_selected fisher $only
        if functions -q fisher
            if _updates_run $dry_run 'fisher update' fisher update
                set --append results "$pass_mark fisher update"
            else
                set --append results "$fail fisher update"
                set --append failures 'fisher update'
            end
        else
            printf '\n==> fisher update\n'
            echo "updates: skipping fisher; not installed" >&2
            set --append results '- fisher update skipped'
        end
    end

    if _updates_selected completions $only
        if _updates_run $dry_run 'fish completions' fish_update_completions
            set --append results "$pass_mark fish_update_completions"
        else
            set --append results "$fail fish_update_completions"
            set --append failures fish_update_completions
        end
    end

    if _updates_selected mise $only
        if command -q mise
            if _updates_run $dry_run 'mise upgrade' mise upgrade
                set --append results "$pass_mark mise upgrade"
            else
                set --append results "$fail mise upgrade"
                set --append failures 'mise upgrade'
            end

            if _updates_run $dry_run 'mise prune' mise prune
                set --append results "$pass_mark mise prune"
            else
                set --append results "$fail mise prune"
                set --append failures 'mise prune'
            end
        else
            printf '\n==> mise\n'
            echo "updates: skipping mise; not installed" >&2
            set --append results '- mise skipped'
        end
    end

    if _updates_selected cleanup $only
        if _updates_run $dry_run 'brew cleanup' brew cleanup
            set --append results "$pass_mark brew cleanup"
        else
            set --append results "$fail brew cleanup"
            set --append failures 'brew cleanup'
        end
    end

    printf '\n==> final status\n'
    printf '%s\n' $results

    if test (count $failures) -gt 0
        printf 'updates: failed: %s\n' (string join ', ' $failures) >&2
        return 1
    end
    if test $dry_run -eq 1
        echo 'Dry run only; no changes made.'
        return 0
    end

    if functions -q confetti
        confetti >/dev/null 2>&1
    end
    return 0
end

function _updates_selected
    set -l component $argv[1]
    set -e argv[1]
    test (count $argv) -eq 0; or contains -- "$component" $argv
end

function _updates_run
    set -l dry_run $argv[1]
    set -l label $argv[2]
    set -e argv[1..2]

    printf '\n==> %s\n' "$label"
    if test $dry_run -eq 1
        printf '  would run: %s\n' (string join ' ' -- $argv)
        return 0
    end
    $argv
end

function _updates_help
    echo 'Usage:'
    echo '  updates [--dry-run] [--only <component>[,<component>...]]'
    echo ''
    echo 'Options:'
    echo '  -n, --dry-run          Preview commands without changing anything'
    echo '  -o, --only COMPONENTS  Run only the comma-separated components'
    echo '  -h, --help             Show this help'
    echo ''
    echo 'Components: brew, bundle, tmux, fisher, completions, mise, cleanup'
end

function updates --description 'Update Homebrew (+ install missing Brewfile entries), tmux TPM plugins, Fisher plugins, and Fish completions'
    set -l failures
    set -l results
    set -l tpm_update "$HOME/.config/tmux/plugins/tpm/bin/update_plugins"
    set -l brewfile "$HOME/.config/Brewfile"
    set -l ok (set_color green)'✓'(set_color normal)
    set -l fail (set_color red)'✗'(set_color normal)

    printf '\n==> brew update\n'
    if brew update
        set --append results "$ok brew update"
    else
        set --append results "$fail brew update"
        set --append failures 'brew update'
    end

    printf '\n==> brew upgrade\n'
    if brew upgrade
        set --append results "$ok brew upgrade"
    else
        set --append results "$fail brew upgrade"
        set --append failures 'brew upgrade'
    end

    printf '\n==> brew bundle install (missing from Brewfile)\n'
    if test -f "$brewfile"
        if brew bundle install --file="$brewfile" --no-upgrade
            set --append results "$ok brew bundle install"
        else
            set --append results "$fail brew bundle install"
            set --append failures 'brew bundle install'
        end
    else
        echo "updates: skipping brew bundle; $brewfile not found" >&2
        set --append results '- brew bundle skipped'
    end

    printf '\n==> tmux TPM plugins\n'
    if test -x "$tpm_update"
        if "$tpm_update" all
            set --append results "$ok tmux TPM plugins"
        else
            set --append results "$fail tmux TPM plugins"
            set --append failures 'tmux TPM plugins'
        end
    else
        echo "updates: skipping tmux TPM plugins; $tpm_update is not executable" >&2
        set --append results '- tmux TPM plugins skipped'
    end

    printf '\n==> fisher update\n'
    if functions -q fisher
        if fisher update
            set --append results "$ok fisher update"
        else
            set --append results "$fail fisher update"
            set --append failures 'fisher update'
        end
    else
        echo "updates: skipping fisher; not installed" >&2
        set --append results '- fisher update skipped'
    end

    printf '\n==> fish completions\n'
    if fish_update_completions
        set --append results "$ok fish_update_completions"
    else
        set --append results "$fail fish_update_completions"
        set --append failures fish_update_completions
    end

    if command -q mise
        printf '\n==> mise upgrade\n'
        if mise upgrade
            set --append results "$ok mise upgrade"
        else
            set --append results "$fail mise upgrade"
            set --append failures 'mise upgrade'
        end

        printf '\n==> mise prune\n'
        if mise prune
            set --append results "$ok mise prune"
        else
            set --append results "$fail mise prune"
            set --append failures 'mise prune'
        end
    else
        printf '\n==> mise\n'
        echo "updates: skipping mise; not installed" >&2
        set --append results '- mise skipped'
    end

    printf '\n==> brew cleanup\n'
    if brew cleanup
        set --append results "$ok brew cleanup"
    else
        set --append results "$fail brew cleanup"
        set --append failures 'brew cleanup'
    end

    printf '\n==> final status\n'
    printf '%s\n' $results

    if test (count $failures) -gt 0
        printf 'updates: failed: %s\n' (string join ', ' $failures) >&2
        return 1
    end

    confetti
end

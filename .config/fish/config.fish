# path setup
fish_add_path /usr/local/bin
fish_add_path /opt/homebrew/bin
fish_add_path "$HOME/.local/bin"

# environment (needed in interactive and non-interactive shells)
set -gx EDITOR nvim
set -gx TERMINAL ghostty
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx NVIM_APPNAME nvim-v12
set -gx CLAUDE_CONFIG_DIR "$HOME/.config/claude"

# suppress window title
function fish_title
end

# interactive-only UI: aliases, key bindings, prompt, fzf, navigation
# (aliases stay out of non-interactive shells so scripts get stock tools,
# e.g. real `find`/`cat` instead of fd/bat)
if status is-interactive
    source ~/.config/fish/alias.fish

    fish_vi_key_bindings

    if functions -q fzf_configure_bindings
        fzf_configure_bindings --directory=\ct --processes=\cp
    end

    if command -q starship
        starship init fish | source
    end

    # zoxide integration to use j and ji keys
    if command -q zoxide
        zoxide init --cmd j fish | source
    end

    # tmux-attention pane ownership. Defines tmux_attention_claim and
    # tmux_attention_disown, which claude.fish and codex.fish compose into the
    # wrappers they already have. Helpers only on purpose: naming commands here
    # would emit `claude`/`codex` functions that replace those, losing the
    # window-rename behavior. Guarded on the path rather than `command -q`
    # because the CLI lives in the tmux plugin dir, not on PATH.
    set -l tmux_attention ~/.config/tmux/plugins/tmux-attention/scripts/tmux-attention
    if test -x $tmux_attention
        $tmux_attention shell-init fish | source
    end
end

# Added by OrbStack: command-line tools and integration
if test -f ~/.orbstack/shell/init2.fish
    source ~/.orbstack/shell/init2.fish
end

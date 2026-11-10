function claude --wraps=claude --description 'Claude Code with clean tmux window name'
    # Work-only auto-mode rules (allow entries, environment notes) live in an untracked file, because this
    # dotfiles repo is public and Claude Code reads `autoMode` only from user/managed settings or `--settings`,
    # never from a settings.local.json. Pass it when present unless the caller chose their own settings, and
    # skip management subcommands that do not start a session.
    set -l config_dir $CLAUDE_CONFIG_DIR
    test -n "$config_dir"; or set config_dir $HOME/.config/claude
    set -l work_settings $config_dir/work-settings.json
    set -l subcommands mcp config update doctor install migrate-installer setup-token plugin auth
    if test -f $work_settings; and not contains -- --settings $argv; and not contains -- "$argv[1]" $subcommands
        set argv --settings $work_settings $argv
    end
    _agent_tmux_run claude $argv
end

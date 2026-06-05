function _coral_config_file
    set -f config_home "$HOME/.config"
    if set -q XDG_CONFIG_HOME; and test -n "$XDG_CONFIG_HOME"
        set config_home "$XDG_CONFIG_HOME"
    end

    printf '%s/coral/config.fish\n' "$config_home"
end

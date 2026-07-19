set -l secrets_file ~/.config/fish/secrets.fish

if test -f "$secrets_file"
    set -l secrets_mode (stat -f '%Lp' "$secrets_file" 2>/dev/null)
    if test -z "$secrets_mode"
        set secrets_mode (stat -c '%a' "$secrets_file" 2>/dev/null)
    end

    if test "$secrets_mode" = 600
        source "$secrets_file"
    else
        printf 'fish: refusing to source %s with permissions %s (expected 600)\n' \
            "$secrets_file" (string escape -- "$secrets_mode") >&2
    end
end

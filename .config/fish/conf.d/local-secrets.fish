set -l secrets_file ~/.config/fish/secrets.fish

if test -f $secrets_file
    source $secrets_file
end

function claude_diff --description 'Toggle Claude Code diff popup on/off'
    set -l flag_file $HOME/.config/claude/flags/diff-popup
    if test -f $flag_file
        rm $flag_file
        echo "Claude diff popup: OFF"
    else
        touch $flag_file
        echo "Claude diff popup: ON"
    end
end

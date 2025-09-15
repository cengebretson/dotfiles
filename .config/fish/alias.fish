alias reload 'exec fish'
alias o 'open'
alias oo 'open .'

# pico8
alias pico8="/Applications/PICO-8.app/Contents/MacOS/pico8"

# misc weather
alias weather "curl -4 'wttr.in/des+moines?format=4'"
alias moon "curl -4 wttr.in/Moon"

# set AWS profile environment variable
alias setaws 'set -x -g AWS_PROFILE'

# updates
alias updates 'brew update && brew upgrade && fish_update_completions && brew cleanup && confetti'
alias center "open -g 'raycast://customWindowManagementCommand?&name=Reasonable%20Center&position=center'"

# eza shortcuts
alias l 'eza --long --all --header --git --icons --no-permissions --no-time --no-user --no-filesize --group-directories-first'
alias ll 'eza -lagh --git --icons --group-directories-first'
alias la 'eza -lagh --git --icons --group-directories-first --sort modified'
alias lc 'clear; and eza --long --all --header --git --icons --no-permissions --no-time --no-user --no-filesize --group-directories-first'
alias lt 'eza -Ta --icons --ignore-glob="node_modules|.git|.vscode|.DS_Store"'
alias ltd 'eza -TaD --icons --ignore-glob="node_modules|.git|.vscode|.DS_Store"'

# networking
alias ipl "ipconfig getifaddr en0" 
alias ipx "curl https://ipinfo.io/ip"
alias flush "sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"

# CLI Tools
alias cat "bat"
alias ping "prettyping --nolegend"
alias find "fd"
alias mkdir "mkdir -p"
alias vi "nvim"
alias vim "nvim"

# git
alias gcopy "git rev-parse --short HEAD | pbcopy"
abbr --add --position anywhere dots -- --git-dir=$HOME/.dotfiles --work-tree=$HOME


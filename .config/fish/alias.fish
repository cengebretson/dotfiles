alias reload='exec fish'
alias o='open'

# misc weather
alias weather="curl -4 'wttr.in/des+moines?format=4'"
alias moon="curl -4 wttr.in/Moon"

# set AWS profile environment variable
alias setaws='set -x -g AWS_PROFILE'

# CLI Tools
alias ipx="curl https://ipinfo.io/ip"
alias cat="bat"
alias ping="prettyping --nolegend"
alias find="fd"
alias mkdir "mkdir -p"
alias gcopy="git rev-parse --short HEAD | pbcopy"

# make sure the --git-dir is the same as the
# directory where you created the repo above.
alias dotfiles="git --git-dir=$HOME/.dotfiles --work-tree=$HOME"

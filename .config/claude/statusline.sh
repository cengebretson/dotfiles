#!/usr/bin/env bash

json=$(cat)
model=$(printf '%s' "$json" | jq -r '(.model | if type == "object" then .id else . end) // ""' 2>/dev/null)
model="${model#claude-}"  # strip "claude-" prefix
vimmode=$(printf '%s' "$json" | jq -r '.vim.mode // ""' 2>/dev/null)
ctx_pct=$(printf '%s' "$json" | jq -r '.context_window.used_percentage // ""' 2>/dev/null)
diff_flag="$HOME/.config/claude/flags/diff-popup"
effort=$(printf '%s' "$json" | jq -r '.effort.level // ""' 2>/dev/null)
thinking=$(printf '%s' "$json" | jq -r '.thinking.enabled // ""' 2>/dev/null)
fast_mode=$(printf '%s' "$json" | jq -r '.fast_mode // ""' 2>/dev/null)

branch=$(git branch --show-current 2>/dev/null)
changes=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

# Catppuccin Mocha
green=$'\033[38;2;166;227;161m'
peach=$'\033[38;2;250;179;135m'
red=$'\033[38;2;243;139;168m'
mauve=$'\033[38;2;203;166;247m'
blue=$'\033[38;2;137;180;250m'
yellow=$'\033[38;2;249;226;175m'
overlay1=$'\033[38;2;127;132;156m'
bold=$'\033[1m'
reset=$'\033[0m'
# Background colors for vim mode blocks
bg_blue=$'\033[48;2;137;180;250m'
bg_green=$'\033[48;2;166;227;161m'
bg_yellow=$'\033[48;2;249;226;175m'
fg_base=$'\033[38;2;30;30;46m'

parts=()

if [[ -n "$vimmode" ]]; then
    case "$vimmode" in
        NORMAL)      parts+=("${bold}${bg_blue}${fg_base} N ${reset}") ;;
        INSERT)      parts+=("${bold}${bg_green}${fg_base} I ${reset}") ;;
        VISUAL)      parts+=("${bold}${bg_yellow}${fg_base} V ${reset}") ;;
        "VISUAL LINE") parts+=("${bold}${bg_yellow}${fg_base} VL ${reset}") ;;
        *)           parts+=("${bold}${overlay1}${vimmode}${reset}") ;;
    esac
fi

if [[ -n "$branch" ]]; then
    seg="${bold}${green}󰘬 ${branch}${reset}"
    if [[ "$changes" -gt 0 ]]; then
        seg+=" ${peach}±${changes}${reset}"
    fi
    parts+=("$seg")
fi

if [[ -n "$model" ]]; then
    parts+=("${bold}${mauve}󱙺 ${model}${reset}")
fi

mode_seg=""
effort_color=""
case "$effort" in
    low)    effort_color="$overlay1"; mode_seg+="${effort_color}󰾆 ■□□□${reset}" ;;
    medium) effort_color="$yellow";   mode_seg+="${effort_color}󰾆 ■■□□${reset}" ;;
    high)   effort_color="$peach";    mode_seg+="${effort_color}󰾆 ■■■□${reset}" ;;
    max)    effort_color="$red";      mode_seg+="${effort_color}󰾆 ■■■■${reset}" ;;
esac
[[ "$thinking" == "true" ]] && mode_seg+=" ${effort_color}󰛨${reset}"
[[ "$fast_mode" == "true" ]] && mode_seg+=" ${yellow}⚡${reset}"
[[ -n "$mode_seg" ]] && parts+=("${mode_seg}")

if [[ -n "$ctx_pct" ]]; then
    if   (( ctx_pct >= 90 )); then ctx_color="$red"
    elif (( ctx_pct >= 75 )); then ctx_color="$peach"
    elif (( ctx_pct >= 50 )); then ctx_color="$yellow"
    else                           ctx_color="$overlay1"
    fi
    filled=$(( ctx_pct * 10 / 100 ))
    bar=""
    for ((i=0; i<10; i++)); do
        (( i < filled )) && bar+="▪" || bar+="▫"
    done
    parts+=("${ctx_color}${bar} ${ctx_pct}%${reset}")
fi

[[ -f "$diff_flag" ]] && parts+=("${green}󰈈${reset}")

sep="${overlay1} │ ${reset}"
result=""
for i in "${!parts[@]}"; do
    [[ $i -gt 0 ]] && result+="$sep"
    result+="${parts[$i]}"
done

printf '%s\n' "$result"

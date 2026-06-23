#!/usr/bin/env bash

json=$(cat)

# One jq pass for every field — five separate jq spawns parsing the same JSON
# was the bulk of the statusline's wall time. Each value lands on its own line.
{
    read -r model
    read -r vimmode
    read -r ctx_pct
    read -r effort
    read -r fast_mode
    read -r session_id
} < <(printf '%s' "$json" | jq -r '
    (.model | if type == "object" then .id else . end) // "",
    .vim.mode // "",
    .context_window.used_percentage // "",
    .effort.level // "",
    .fast_mode // "",
    .session_id // ""' 2>/dev/null)
model="${model#claude-}"  # strip "claude-" prefix

# One git pass for branch + change count: `git status --branch --porcelain`
# carries the branch on its first line (`## branch...upstream`), so we avoid a
# second `git branch` spawn. Branch and count come straight out of parameter
# expansion — no mapfile (bash 4+) and no `wc` subprocess.
branch=""
changes=0
wt_name=""
git_out=$(git status --porcelain=v1 --branch 2>/dev/null)
if [[ -n "$git_out" ]]; then
    first="${git_out%%$'\n'*}"  # "## branch...upstream [ahead N]"
    branch="${first#\#\# }"     # drop the leading "## "
    branch="${branch%%...*}"    # strip "...upstream" when tracking
    branch="${branch%% *}"      # strip trailing " [ahead N]" when not
    # change count = number of newlines (every status line after the branch
    # line); strip all non-newline chars and measure what's left.
    nl="${git_out//[!$'\n']/}"
    changes=${#nl}

    # One extra git pass, only when we're in a repo: git-dir tells us whether
    # this checkout is a linked worktree (path contains .git/worktrees/<name>),
    # and short HEAD gives a readable label for detached worktrees that would
    # otherwise show a bare "HEAD" (the --fast setup-worktree default).
    shortsha=""
    { read -r gitdir; read -r shortsha; } < <(git rev-parse --git-dir --short HEAD 2>/dev/null)
    case "$gitdir" in
        */worktrees/*) wt_name="${gitdir#*/worktrees/}"; wt_name="${wt_name%%/*}" ;;
    esac
    # Detached HEAD (status reports "## HEAD (no branch)" -> branch=="HEAD"):
    # show the short SHA instead of the uninformative literal "HEAD".
    if [[ "$branch" == "HEAD" ]]; then
        branch="@${shortsha:-detached}"
    fi
fi

# Catppuccin Mocha
green=$'\033[38;2;166;227;161m'
teal=$'\033[38;2;148;226;213m'
peach=$'\033[38;2;250;179;135m'
red=$'\033[38;2;243;139;168m'
mauve=$'\033[38;2;203;166;247m'
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
    seg="${bold}"
    # Worktree badge: a peach "forked repo" glyph in front of the branch makes
    # a linked worktree visually distinct from the primary checkout at a glance.
    [[ -n "$wt_name" ]] && seg+="${peach} ${reset}${bold}"
    seg+="${green}󰘬 ${branch}${reset}"
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
effort_icon="󰛨"
case "$effort" in
    low)    effort_color="$overlay1"; mode_seg+="${effort_color}${effort_icon} ▪${reset}" ;;
    medium) effort_color="$yellow";   mode_seg+="${effort_color}${effort_icon} ▪▪${reset}" ;;
    high)   effort_color="$peach";    mode_seg+="${effort_color}${effort_icon} ▪▪▪${reset}" ;;
    xhigh)  effort_color="$peach";    mode_seg+="${effort_color}${effort_icon} ▪▪▪▪${reset}" ;;
    max)    effort_color="$red";      mode_seg+="${effort_color}${effort_icon} ▪▪▪▪▪${reset}" ;;
esac
[[ "$fast_mode" == "true" ]] && mode_seg+=" ${yellow}⚡${reset}"
[[ -n "$mode_seg" ]] && parts+=("${mode_seg}")

# context-mode savings — first KPI block from its statusline command
# (e.g. "14.6 KB kept out" / "2.1 KB this chat"); skip the no-data
# marketing headline ("saves ~98% ...") and fail silently if unavailable
ctxmode_root="$HOME/.config/claude/plugins/marketplaces/context-mode"
ctxmode_bin="$ctxmode_root/bin/statusline.mjs"
# plugin updates wipe the compiled build/ the statusline command needs for
# real numbers — rebuild it in the background, at most once per hour
if [[ -f "$ctxmode_bin" && ! -f "$ctxmode_root/build/session/analytics.js" ]]; then
    stamp="${TMPDIR:-/tmp}/ctxmode-statusline-rebuild"
    if [[ ! -f "$stamp" ]] || [[ -n "$(find "$stamp" -mmin +60 2>/dev/null)" ]]; then
        touch "$stamp"
        (cd "$ctxmode_root" && npx tsc) >/dev/null 2>&1 &
    fi
fi
if [[ -f "$ctxmode_bin" ]] && command -v node >/dev/null 2>&1; then
    # The node call is the statusline's biggest cost (~35ms). The savings figure
    # barely moves between refreshes, so cache it per session for 30s and reuse
    # the cached value on every refresh in that window.
    ctx_cache="${TMPDIR:-/tmp}/ctxmode-sl-${session_id:-default}.cache"
    ctx_saved=""
    now=$(date +%s)
    mtime=$(stat -f %m "$ctx_cache" 2>/dev/null || stat -c %Y "$ctx_cache" 2>/dev/null)
    if [[ -n "$mtime" ]] && (( now - mtime < 30 )); then
        ctx_saved=$(<"$ctx_cache")
    else
        ctx_saved=$(printf '%s' "$json" | node "$ctxmode_bin" 2>/dev/null \
            | sed -E 's/.*●[[:space:]]*//; s/[[:space:]]+·.*//')
        printf '%s' "$ctx_saved" > "$ctx_cache" 2>/dev/null
    fi
    if [[ -n "$ctx_saved" && "$ctx_saved" != saves* ]]; then
        parts+=("${teal}󰆼 ${ctx_saved}${reset}")
    fi
fi

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

sep="${overlay1} | ${reset}"
result=""
for i in "${!parts[@]}"; do
    [[ $i -gt 0 ]] && result+="$sep"
    result+="${parts[$i]}"
done

printf '%s\n' "$result"

#!/usr/bin/env bash

run_dotfiles_doctor() {
	local dot_git="$HOME/.dotfiles" work_tree="$HOME"
	doctor_init 24
	doctor_heading dotfiles "Bare dotfiles repo readiness"

	dot_git() {
		git -C "$work_tree" --git-dir="$dot_git" --work-tree="$work_tree" "$@"
	}

	dot_is_tracked() {
		dot_git ls-files --error-unmatch "$1" >/dev/null 2>&1
	}

	dot_check_tracked() {
		if dot_is_tracked "$1"; then doctor_line ok tracked "$1"; else doctor_line warn tracked "$1 missing"; fi
	}

	dot_check_untracked() {
		local rel="$1"
		if dot_is_tracked "$rel"; then
			doctor_line fail protected "$rel is tracked"
		elif [[ -e "$work_tree/$rel" ]]; then
			doctor_line ok protected "$rel untracked"
		else
			doctor_line ok protected "$rel absent"
		fi
	}

	dot_check_private() {
		local rel="$1" expected="${2:-600}" path="$work_tree/$1" mode
		dot_check_untracked "$rel"
		[[ -e "$path" ]] || return
		mode="$(doctor_file_mode "$path")"
		if [[ "$mode" = "$expected" ]]; then doctor_line ok permissions "$rel mode $mode"; else doctor_line fail permissions "$rel mode ${mode:-unknown} (expected $expected)"; fi
	}

	dot_check_fish() {
		local rel="$1" path="$work_tree/$1"
		[[ -f "$path" ]] || return
		if ! doctor_have fish; then
			doctor_line warn fish "$rel — fish missing"
		elif fish -n "$path" >/dev/null 2>&1; then
			doctor_line ok fish "$rel"
		else
			doctor_line fail fish "$rel"
		fi
		if doctor_have fish_indent; then
			if fish_indent --check "$path" >/dev/null 2>&1; then doctor_line ok fish-format "$rel"; else doctor_line fail fish-format "$rel"; fi
		fi
	}

	dot_check_bash() {
		local rel="$1" path="$work_tree/$1"
		[[ -f "$path" ]] && head -1 "$path" | grep -q bash || return
		if bash -n "$path" >/dev/null 2>&1; then doctor_line ok bash "$rel"; else doctor_line fail bash "$rel"; fi
		if doctor_have shellcheck; then
			if shellcheck -x -S style "$path" >/dev/null 2>&1; then doctor_line ok shellcheck "$rel"; else doctor_line fail shellcheck "$rel"; fi
		else
			doctor_line warn shellcheck "$rel — missing"
		fi
	}

	dot_check_lua() {
		local rel="$1" path="$work_tree/$1"
		[[ -f "$path" ]] || return
		if ! doctor_have luac; then
			doctor_line warn lua "$rel — luac missing"
		elif luac -p "$path" >/dev/null 2>&1; then
			doctor_line ok lua "$rel"
		else
			doctor_line fail lua "$rel"
		fi
	}

	doctor_section "Repository"
	if [[ -d "$dot_git" ]]; then doctor_line ok gitdir "$dot_git"; else doctor_line fail gitdir "$dot_git missing"; fi
	if git --git-dir="$dot_git" rev-parse --is-bare-repository >/dev/null 2>&1; then doctor_line ok mode "explicit gitdir + work-tree"; else doctor_line fail repository "cannot inspect"; fi

	doctor_section "Changes"
	local status untracked
	status="$(dot_git status --short 2>/dev/null)"
	if [[ -n "$status" ]]; then
		doctor_line warn status "$(doctor_count_lines "$status") changed paths"
		printf '%s\n' "$status" | sed 's/^/    /'
	else
		doctor_line ok status clean
	fi

	untracked="$(
		dot_git status --short --untracked-files=all -- \
			.config/AI-SETUP.md .config/Brewfile .config/claude .config/codex .config/fish .config/git .local/bin .local/lib/doctor .local/lib/git-release .gitconfig .gitignore .tmux.conf 2>/dev/null |
			awk '$1 == "??" {print $2}' |
			grep -Ev '^(\.config/codex/(plugins/cache|sessions|context-mode|\.tmp|process_manager|plugins/\.plugin-appserver)/|\.config/codex/chrome-native-hosts\.json$|\.config/claude/(projects/|settings\.json\.bak)|\.config/fish/(completions|conf\.d|functions)/|\.config/fish/fish_variables$)' || true
	)"
	if [[ -n "$untracked" ]]; then
		doctor_line warn untracked "$(doctor_count_lines "$untracked") paths"
		printf '%s\n' "$untracked" | sed -n '1,40{s/^/    /;p;}'
	else
		doctor_line ok untracked none
	fi

	doctor_section "Protected local files"
	dot_check_untracked .config/git/config.local
	dot_check_private .config/fish/secrets.fish
	dot_check_untracked .config/claude/.claude.json
	dot_check_untracked .config/codex/config.toml

	doctor_section "Expected tracked files"
	local rel
	for rel in .local/bin/doctor .local/bin/docker-maint .local/bin/git-release .local/lib/doctor/common.sh .local/lib/doctor/ai.sh .local/lib/doctor/docker.sh .local/lib/doctor/docker-maint.sh .local/lib/doctor/dotfiles.sh .local/lib/git-release/common.sh .local/lib/git-release/version.sh .local/lib/git-release/changelog.sh .local/lib/git-release/workflow.sh .config/codex/config.shared.toml .config/fish/config.fish .config/AI-SETUP.md; do
		dot_check_tracked "$rel"
	done

	doctor_section "Tracked-file syntax"
	local files
	files="$(dot_git ls-files '.config/fish/*.fish' '.config/fish/**/*.fish' 2>/dev/null)"
	while IFS= read -r rel; do [[ -n "$rel" ]] && dot_check_fish "$rel"; done < <(printf '%s\n' "$files")
	files="$(dot_git ls-files '.local/bin/*' '.local/lib/doctor/*.sh' '.local/lib/git-release/*.sh' '.config/git/tests/*.sh' 2>/dev/null)"
	while IFS= read -r rel; do [[ -n "$rel" ]] && dot_check_bash "$rel"; done < <(printf '%s\n' "$files")
	files="$(dot_git ls-files '.config/nvim/*.lua' '.config/nvim/**/*.lua' 2>/dev/null)"
	while IFS= read -r rel; do [[ -n "$rel" ]] && dot_check_lua "$rel"; done < <(printf '%s\n' "$files")

	doctor_summary
}

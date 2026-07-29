#!/usr/bin/env bash

run_dotfiles_doctor() {
	local dot_git="$HOME/.dotfiles" work_tree="$HOME"
	local verbose=0
	local dot_fish_missing_reported=0 dot_fish_indent_missing_reported=0
	local dot_shellcheck_missing_reported=0 dot_luac_missing_reported=0
	[[ "${1:-}" = --verbose ]] && verbose=1
	doctor_init 24
	doctor_heading dotfiles "Bare dotfiles repo readiness"

	dot_git() {
		git -C "$work_tree" --git-dir="$dot_git" --work-tree="$work_tree" "$@"
	}

	dot_is_tracked() {
		dot_git ls-files --error-unmatch "$1" >/dev/null 2>&1
	}

	dot_verbose_ok() {
		[[ "$verbose" = 1 ]] && doctor_line ok "$@"
		return 0
	}

	dot_group_summary() {
		local label="$1" detail="$2" fails_before="$3" warns_before="$4"
		[[ "$verbose" = 1 ]] && return
		if [[ "$DOCTOR_FAILS" -eq "$fails_before" && "$DOCTOR_WARNS" -eq "$warns_before" ]]; then
			doctor_line ok "$label" "$detail"
		else
			doctor_line note "$label" "$detail checked"
		fi
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
			if [[ "$dot_fish_missing_reported" -eq 0 ]]; then
				doctor_line warn fish "fish missing"
				dot_fish_missing_reported=1
			fi
		elif fish -n "$path" >/dev/null 2>&1; then
			dot_verbose_ok fish "$rel"
		else
			doctor_line fail fish "$rel"
		fi
		if doctor_have fish_indent; then
			if fish_indent --check "$path" >/dev/null 2>&1; then dot_verbose_ok fish-format "$rel"; else doctor_line warn fish-format "$rel"; fi
		elif [[ "$dot_fish_indent_missing_reported" -eq 0 ]]; then
			doctor_line warn fish-format "fish_indent missing"
			dot_fish_indent_missing_reported=1
		fi
	}

	dot_check_bash() {
		local rel="$1" path="$work_tree/$1"
		[[ -f "$path" ]] && head -1 "$path" | grep -q bash || return 1
		if bash -n "$path" >/dev/null 2>&1; then dot_verbose_ok bash "$rel"; else doctor_line fail bash "$rel"; fi
		if doctor_have shellcheck; then
			if shellcheck -x -S style "$path" >/dev/null 2>&1; then dot_verbose_ok shellcheck "$rel"; else doctor_line fail shellcheck "$rel"; fi
		elif [[ "$dot_shellcheck_missing_reported" -eq 0 ]]; then
			doctor_line warn shellcheck "missing"
			dot_shellcheck_missing_reported=1
		fi
		return 0
	}

	dot_check_lua() {
		local rel="$1" path="$work_tree/$1"
		[[ -f "$path" ]] || return
		if ! doctor_have luac; then
			if [[ "$dot_luac_missing_reported" -eq 0 ]]; then
				doctor_line warn lua "luac missing"
				dot_luac_missing_reported=1
			fi
		elif luac -p "$path" >/dev/null 2>&1; then
			dot_verbose_ok lua "$rel"
		else
			doctor_line fail lua "$rel"
		fi
	}

	dot_expected_untracked() {
		local rel="$1"
		[[ -L "$work_tree/$rel" ]] && return 0
		case "$rel" in
		.config/claude/hooks/handlers/agent-turn-stop | \
			.config/claude/image-cache/* | \
			.config/claude/projects/* | \
			.config/claude/settings.json.bak | \
			.config/codex/.sandbox_migration | \
			.config/codex/chrome-native-hosts.json | \
			.config/codex/context-mode/* | \
			.config/codex/mcp-oauth-locks/* | \
			.config/codex/plugins/.plugin-appserver/* | \
			.config/codex/plugins/cache/* | \
			.config/codex/process_manager/* | \
			.config/codex/sessions/* | \
			.config/codex/.tmp/* | \
			.config/codex/hooks/handlers/agent-turn-stop | \
			.config/fish/completions/* | \
			.config/fish/conf.d/* | \
			.config/fish/functions/* | \
			.config/fish/fish_variables)
			return 0
			;;
		esac
		return 1
	}

	doctor_section "Repository"
	if [[ -d "$dot_git" ]]; then doctor_line ok gitdir "$dot_git"; else doctor_line fail gitdir "$dot_git missing"; fi
	if git --git-dir="$dot_git" rev-parse --is-bare-repository >/dev/null 2>&1; then doctor_line ok mode "explicit gitdir + work-tree"; else doctor_line fail repository "cannot inspect"; fi

	doctor_section "Changes"
	local status rel record
	local -a untracked=()
	status="$(dot_git status --short 2>/dev/null)"
	if [[ -n "$status" ]]; then
		doctor_line warn status "$(doctor_count_lines "$status") changed paths"
		printf '%s\n' "$status" | sed 's/^/    /'
	else
		doctor_line ok status clean
	fi

	while IFS= read -r -d '' record; do
		[[ "$record" = "? "* ]] || continue
		rel="${record#"? "}"
		dot_expected_untracked "$rel" || untracked+=("$rel")
	done < <(
		dot_git status --porcelain=v2 -z --untracked-files=normal -- \
			.config/AI-SETUP.md .config/Brewfile .config/claude .config/codex .config/fish .config/git .local/bin .local/lib/doctor .local/lib/git-release .gitconfig .gitignore .tmux.conf 2>/dev/null
	)
	if [[ "${#untracked[@]}" -gt 0 ]]; then
		doctor_line warn untracked "${#untracked[@]} paths"
		printf '    %s\n' "${untracked[@]:0:40}"
	else
		doctor_line ok untracked none
	fi

	doctor_section "Protected local files"
	dot_check_untracked .config/git/config.local
	dot_check_private .config/fish/secrets.fish
	dot_check_untracked .config/claude/.claude.json
	dot_check_untracked .config/codex/config.toml

	doctor_section "Expected tracked files"
	local missing_tracked=0
	local -a expected_tracked=(
		.local/bin/doctor
		.local/bin/docker-maint
		.local/bin/git-release
		.local/lib/doctor/common.sh
		.local/lib/doctor/ai.sh
		.local/lib/doctor/docker.sh
		.local/lib/doctor/docker-maint.sh
		.local/lib/doctor/dotfiles.sh
		.local/lib/git-release/common.sh
		.local/lib/git-release/version.sh
		.local/lib/git-release/changelog.sh
		.local/lib/git-release/workflow.sh
		.config/codex/config.shared.toml
		.config/fish/config.fish
		.config/AI-SETUP.md
	)
	for rel in "${expected_tracked[@]}"; do
		if dot_is_tracked "$rel"; then
			dot_verbose_ok tracked "$rel"
		else
			doctor_line warn tracked "$rel missing"
			missing_tracked=$((missing_tracked + 1))
		fi
	done
	if [[ "$verbose" != 1 ]]; then
		if [[ "$missing_tracked" -eq 0 ]]; then
			doctor_line ok tracked "${#expected_tracked[@]} expected files"
		else
			doctor_line note tracked "$((${#expected_tracked[@]} - missing_tracked))/${#expected_tracked[@]} expected files found"
		fi
	fi

	doctor_section "Tracked-file syntax"
	local files file_count fails_before warns_before
	files="$(dot_git ls-files '.config/fish/*.fish' '.config/fish/**/*.fish' 2>/dev/null)"
	file_count=0
	fails_before=$DOCTOR_FAILS
	warns_before=$DOCTOR_WARNS
	while IFS= read -r rel; do
		[[ -n "$rel" ]] || continue
		file_count=$((file_count + 1))
		dot_check_fish "$rel"
	done < <(printf '%s\n' "$files")
	dot_group_summary fish "$file_count files, syntax + format" "$fails_before" "$warns_before"

	files="$(dot_git ls-files '.local/bin/*' '.local/lib/doctor/*.sh' '.local/lib/git-release/*.sh' '.config/git/tests/*.sh' 2>/dev/null)"
	file_count=0
	fails_before=$DOCTOR_FAILS
	warns_before=$DOCTOR_WARNS
	while IFS= read -r rel; do
		[[ -n "$rel" ]] || continue
		if dot_check_bash "$rel"; then file_count=$((file_count + 1)); fi
	done < <(printf '%s\n' "$files")
	dot_group_summary bash "$file_count files, syntax + ShellCheck" "$fails_before" "$warns_before"

	files="$(dot_git ls-files '.config/nvim/*.lua' '.config/nvim/**/*.lua' 2>/dev/null)"
	file_count=0
	fails_before=$DOCTOR_FAILS
	warns_before=$DOCTOR_WARNS
	while IFS= read -r rel; do
		[[ -n "$rel" ]] || continue
		file_count=$((file_count + 1))
		dot_check_lua "$rel"
	done < <(printf '%s\n' "$files")
	if [[ "$file_count" -gt 0 ]]; then dot_group_summary lua "$file_count files, syntax" "$fails_before" "$warns_before"; fi

	doctor_summary
}

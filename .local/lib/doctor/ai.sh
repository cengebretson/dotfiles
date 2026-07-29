#!/usr/bin/env bash

run_ai_doctor() {
	local claude_dir="$HOME/.config/claude"
	local codex_dir="$HOME/.config/codex"
	local tmux_attention="$HOME/.config/tmux/plugins/tmux-attention/scripts/tmux-attention"
	local codex_plugin_output='' codex_mcp_output=''
	local codex_plugin_status=127 codex_mcp_status=127
	local plugins_enabled='' plugins_disabled='' mcp_seen=''

	doctor_init 23
	doctor_heading ai "Claude Code + Codex readiness"

	ai_check_json() {
		local path="$1" label="$2"
		if [[ ! -f "$path" ]]; then
			doctor_line warn "$label" "missing"
		elif doctor_have jq && jq empty "$path" >/dev/null 2>&1; then
			doctor_line ok "$label" "valid JSON"
		elif doctor_have jq; then
			doctor_line fail "$label" "invalid JSON"
		else
			doctor_line warn "$label" "jq missing — cannot validate"
		fi
	}

	ai_check_toml() {
		local path="$1" label="$2"
		if [[ ! -f "$path" ]]; then
			doctor_line warn "$label" "missing"
		elif doctor_have yq; then
			if yq -p toml -o json '.' "$path" >/dev/null 2>&1; then
				doctor_line ok "$label" "valid TOML"
			else
				doctor_line fail "$label" "invalid TOML"
			fi
		elif doctor_have python3 && python3 -c 'import tomllib' >/dev/null 2>&1; then
			if python3 - "$path" >/dev/null 2>&1 <<'PY'; then
import pathlib
import sys
import tomllib

tomllib.loads(pathlib.Path(sys.argv[1]).read_text())
PY
				doctor_line ok "$label" "valid TOML"
			else
				doctor_line fail "$label" "invalid TOML"
			fi
		else
			doctor_line warn "$label" "yq or Python tomllib unavailable"
		fi
	}

	ai_check_handlers() {
		local dir="$1" handler label
		if [[ ! -d "$dir" ]]; then
			doctor_line warn handlers "missing directory: $dir"
			return
		fi
		for handler in "$dir"/*; do
			[[ -e "$handler" || -L "$handler" ]] || continue
			label="handler:$(basename "$handler")"
			if [[ -x "$handler" ]]; then
				doctor_line ok "$label"
			elif [[ -L "$handler" && ! -e "$handler" ]]; then
				doctor_line warn "$label" "symlink target missing"
			else
				doctor_line fail "$label" "not executable"
			fi
		done
	}

	ai_check_route() {
		local path="$1"
		if [[ -f "$path" ]] && grep -q 'dispatch.sh' "$path"; then
			doctor_line ok config "$(basename "$path")"
		else
			doctor_line warn config "$(basename "$path") — no dispatch.sh route"
		fi
	}

	ai_check_shadow() {
		local cmd="$1" matches first second count detail first_version second_version
		if ! doctor_have "$cmd"; then
			doctor_line warn "$cmd" "not found"
			return
		fi

		matches="$(type -a "$cmd" 2>/dev/null | awk '{print $NF}')"
		first="$(printf '%s\n' "$matches" | sed -n '1p')"
		count="$(doctor_count_lines "$matches")"
		if [[ "$count" -le 1 ]]; then
			doctor_line ok "$cmd" "$first"
			return
		fi

		second="$(printf '%s\n' "$matches" | sed -n '2p')"
		first_version="$($first --version 2>/dev/null | head -n 1 || true)"
		second_version="$($second --version 2>/dev/null | head -n 1 || true)"
		detail="shadowed: $first"
		[[ -n "$first_version" ]] && detail="$detail ($first_version)"
		detail="$detail; also $second"
		[[ -n "$second_version" ]] && detail="$detail ($second_version)"
		[[ "$count" -gt 2 ]] && detail="$detail (+$((count - 2)) more)"
		doctor_line warn "$cmd" "$detail"
	}

	ai_list_skills() {
		local dir="$1" path
		[[ -d "$dir" ]] || return
		for path in "$dir"/*/; do
			[[ -d "$path" ]] && basename "$path"
		done
	}

	ai_skill_has() {
		ai_list_skills "$1" | grep -qx "$2"
	}

	ai_skill_is_shared() {
		[[ -d "$HOME/.agents/skills/$1" ]]
	}

	ai_is_plugin() {
		printf '%s\n' "$plugins_enabled" | grep -qx "$1"
	}

	ai_is_mcp() {
		printf '%s\n' "$mcp_seen" | grep -qx "$1"
	}

	doctor_section "Commands"
	for cmd in codex gh claude doctor; do
		ai_check_shadow "$cmd"
	done
	for cmd in git bash jq yq python3 node npx fish rg shellcheck shfmt; do
		if doctor_have "$cmd"; then
			doctor_line ok "$cmd"
		else
			doctor_line warn "$cmd" "missing — check ~/.config/Brewfile"
		fi
	done

	doctor_section "Execution context"
	if [[ -n "${CODEX_SANDBOX:-}" ]]; then
		local context_detail="Codex sandbox ($CODEX_SANDBOX)"
		[[ "${CODEX_SANDBOX_NETWORK_DISABLED:-}" = 1 ]] && context_detail="$context_detail; network restricted"
		doctor_line note context "$context_detail"
	else
		doctor_line ok context "host shell"
	fi

	doctor_section "Claude hooks"
	doctor_check_executable "$HOME/.local/bin/ai-hook-dispatch" "shared dispatcher"
	doctor_check_executable "$claude_dir/hooks/dispatch.sh" "dispatch symlink"
	ai_check_handlers "$claude_dir/hooks/handlers"
	ai_check_route "$claude_dir/settings.json"

	doctor_section "Codex hooks"
	doctor_check_executable "$codex_dir/hooks/dispatch.sh" "dispatch symlink"
	ai_check_handlers "$codex_dir/hooks/handlers"
	ai_check_route "$codex_dir/hooks.json"

	doctor_section "Hook prerequisites"
	if [[ -x "$tmux_attention" ]]; then doctor_line ok tmux-attention; else doctor_line warn tmux-attention "attention handlers skip"; fi
	if doctor_have moshi-hook || [[ -x /opt/homebrew/bin/moshi-hook ]]; then doctor_line ok moshi-hook; else doctor_line note moshi-hook "optional; Moshi handlers skip"; fi
	doctor_check_executable "$claude_dir/hooks/format-on-edit.sh" format-on-edit
	doctor_check_executable "$claude_dir/hooks/approve-compound-bash.sh" approve-compound-bash
	if [[ -f "$claude_dir/hooks/context-mode-cache-heal.mjs" ]]; then doctor_line ok context-mode-cache-heal; else doctor_line warn context-mode-cache-heal "heal handler skips"; fi
	if [[ -x /opt/homebrew/bin/bash || -x /usr/local/bin/bash ]]; then doctor_line ok modern-bash; else doctor_line warn modern-bash "approve hook needs Bash 4.3+"; fi

	doctor_section "Config syntax"
	ai_check_json "$claude_dir/settings.json" "claude settings"
	ai_check_json "$codex_dir/hooks.json" "codex hooks"
	ai_check_toml "$codex_dir/config.shared.toml" "codex shared"
	[[ -f "$codex_dir/config.toml" ]] && ai_check_toml "$codex_dir/config.toml" "codex local"
	if [[ -e "$HOME/.config/fish/secrets.fish" ]]; then
		local mode
		mode="$(doctor_file_mode "$HOME/.config/fish/secrets.fish")"
		if [[ "$mode" = 600 ]]; then doctor_line ok "fish secrets" "mode 600"; else doctor_line fail "fish secrets" "mode ${mode:-unknown} (expected 600)"; fi
	fi

	doctor_section "Authentication and Codex"
	if gh auth status >/dev/null 2>&1; then
		doctor_line ok gh "authenticated"
	elif [[ -n "${CODEX_SANDBOX:-}" ]]; then
		doctor_line note gh "sandbox-limited; verify in host shell"
	else
		doctor_line warn gh "auth status failed"
	fi

	if doctor_have codex; then
		local codex_version
		codex_version="$(codex --version 2>/dev/null | head -n 1)"
		if [[ -n "$codex_version" ]]; then
			doctor_line ok codex "$codex_version"
		else
			doctor_line warn codex "version unavailable"
		fi

		if doctor_have jq && codex_plugin_output="$(codex plugin list --json 2>/dev/null)" && jq -e '.installed | type == "array"' >/dev/null 2>&1 <<<"$codex_plugin_output"; then
			codex_plugin_status=0
			plugins_enabled="$(jq -r '.installed[]? | select(.installed and .enabled) | .name' <<<"$codex_plugin_output")"
			plugins_disabled="$(jq -r '.installed[]? | select(.installed and (.enabled | not)) | .name' <<<"$codex_plugin_output")"
			doctor_line ok codex-plugins "list ok"
		else
			doctor_line warn codex-plugins "list failed"
		fi
		if doctor_have jq && codex_mcp_output="$(codex mcp list --json 2>/dev/null)" && jq -e 'type == "array"' >/dev/null 2>&1 <<<"$codex_mcp_output"; then
			codex_mcp_status=0
			mcp_seen="$(jq -r '.[]? | select(.enabled) | .name' <<<"$codex_mcp_output")"
			doctor_line ok codex-mcp "list ok"
		else
			doctor_line warn codex-mcp "list failed"
		fi
	fi

	doctor_section "Integrations"
	if doctor_have jq; then
		while IFS= read -r plugin; do
			[[ -n "$plugin" ]] && doctor_line ok "$plugin" "Claude plugin"
		done < <(jq -r '.enabledPlugins // {} | to_entries[] | select(.value) | .key' "$claude_dir/settings.json" 2>/dev/null)
	fi
	if [[ "$codex_mcp_status" -eq 0 ]]; then
		while IFS=$'\t' read -r name auth_status; do
			[[ -n "$name" ]] || continue
			local source
			source=mcp
			ai_is_plugin "$name" && source="plugin + mcp"
			if [[ "$auth_status" = not_logged_in ]]; then doctor_line warn "$name" "$source · not logged in"; else doctor_line ok "$name" "$source"; fi
		done < <(jq -r '.[]? | select(.enabled) | [.name, (.auth_status // "unknown")] | @tsv' <<<"$codex_mcp_output")
	fi
	while IFS= read -r plugin; do
		[[ -n "$plugin" ]] && ! ai_is_mcp "$plugin" && doctor_line ok "$plugin" "plugin"
	done < <(printf '%s\n' "$plugins_enabled")
	while IFS= read -r plugin; do
		[[ -n "$plugin" ]] || continue
		if [[ "$plugin" = atlassian-rovo ]]; then doctor_line note "$plugin" "disabled; acli is primary"; else doctor_line warn "$plugin" "plugin disabled"; fi
	done < <(printf '%s\n' "$plugins_disabled")

	if doctor_have moshi-hook; then
		local moshi_status
		moshi_status="$(moshi-hook status 2>/dev/null)"
		if printf '%s' "$moshi_status" | grep -q 'status:.*paired' && ! printf '%s' "$moshi_status" | grep -q 'status:.*unpaired' && pgrep -f 'moshi-hook serve' >/dev/null 2>&1; then
			doctor_line ok moshi "paired and running"
		elif [[ "${DOCTOR_REQUIRE_MOSHI:-0}" = 1 ]]; then
			doctor_line warn moshi "not paired or daemon stopped"
		else
			doctor_line note moshi "installed but inactive; optional"
		fi
	fi

	doctor_section "Skills parity"
	local parity_warns skill
	parity_warns=$DOCTOR_WARNS
	while IFS= read -r skill; do
		case "$skill" in ctx-browser-debug | ctx-resume | ctx-triage | fast-loop | playwright) continue ;; esac
		[[ -n "$skill" ]] && { ai_skill_has "$codex_dir/skills" "$skill" || ai_skill_is_shared "$skill" || doctor_line warn skills "Claude-only: $skill"; }
	done < <(ai_list_skills "$claude_dir/skills")
	while IFS= read -r skill; do
		case "$skill" in ctx-browser-debug | ctx-resume | ctx-triage | fast-loop | playwright) continue ;; esac
		[[ -n "$skill" ]] && { ai_skill_has "$claude_dir/skills" "$skill" || ai_skill_is_shared "$skill" || doctor_line warn skills "Codex-only: $skill"; }
	done < <(ai_list_skills "$codex_dir/skills")
	[[ "$DOCTOR_WARNS" -eq "$parity_warns" ]] && doctor_line ok skills "in sync (documented exemptions ignored)"

	doctor_section "Required components"
	for skill in health-check fast-loop; do
		if ai_skill_has "$codex_dir/skills" "$skill"; then doctor_line ok "skill:$skill"; else doctor_line warn "skill:$skill" "missing"; fi
	done
	local component
	for component in context-mode github; do
		if [[ "$codex_plugin_status" -eq 0 ]] && ai_is_plugin "$component"; then
			doctor_line ok "plugin:$component"
		elif [[ "$codex_mcp_status" -eq 0 ]] && ai_is_mcp "$component"; then
			doctor_line ok "mcp:$component"
		else
			doctor_line warn "$component" "plugin/mcp missing"
		fi
	done
	doctor_line note browser "session-scoped; checked by health-check"

	doctor_summary
}

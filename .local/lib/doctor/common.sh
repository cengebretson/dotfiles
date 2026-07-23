#!/usr/bin/env bash

doctor_init() {
	DOCTOR_FAILS=0
	DOCTOR_WARNS=0
	DOCTOR_LABEL_WIDTH="${1:-23}"

	if [[ -t 1 ]]; then
		DOCTOR_RESET=$'\033[0m'
		DOCTOR_DIM=$'\033[2m'
		DOCTOR_BOLD=$'\033[1m'
		DOCTOR_GREEN=$'\033[32m'
		DOCTOR_YELLOW=$'\033[33m'
		DOCTOR_RED=$'\033[31m'
		DOCTOR_HEAD=$'\033[1;36m'
	else
		DOCTOR_RESET=''
		DOCTOR_DIM=''
		DOCTOR_BOLD=''
		DOCTOR_GREEN=''
		DOCTOR_YELLOW=''
		DOCTOR_RED=''
		DOCTOR_HEAD=''
	fi
}

doctor_have() {
	command -v "$1" >/dev/null 2>&1
}

doctor_line() {
	local status="$1" label="$2" detail="${3:-}" symbol color

	case "$status" in
	ok)
		symbol='✓'
		color=$DOCTOR_GREEN
		;;
	warn)
		symbol='⚠'
		color=$DOCTOR_YELLOW
		DOCTOR_WARNS=$((DOCTOR_WARNS + 1))
		;;
	fail)
		symbol='✗'
		color=$DOCTOR_RED
		DOCTOR_FAILS=$((DOCTOR_FAILS + 1))
		;;
	*)
		symbol='·'
		color=''
		;;
	esac

	if [[ -n "$detail" ]]; then
		printf '  %s%s%s %-*s %s%s%s\n' "$color" "$symbol" "$DOCTOR_RESET" "$DOCTOR_LABEL_WIDTH" "$label" "$DOCTOR_DIM" "$detail" "$DOCTOR_RESET"
	else
		printf '  %s%s%s %s\n' "$color" "$symbol" "$DOCTOR_RESET" "$label"
	fi
}

doctor_section() {
	printf '\n%s▸ %s%s\n' "$DOCTOR_HEAD" "$1" "$DOCTOR_RESET"
}

doctor_heading() {
	printf '%sdoctor %s%s  %s%s%s\n' "$DOCTOR_BOLD" "$1" "$DOCTOR_RESET" "$DOCTOR_DIM" "$2" "$DOCTOR_RESET"
}

doctor_summary() {
	doctor_section "Summary"
	if [[ "$DOCTOR_FAILS" -gt 0 ]]; then
		printf '  %s✗ %d fail%s · %s⚠ %d warn%s\n' "$DOCTOR_RED" "$DOCTOR_FAILS" "$DOCTOR_RESET" "$DOCTOR_YELLOW" "$DOCTOR_WARNS" "$DOCTOR_RESET"
		printf '  %sNext: resolve the failures above.%s\n' "$DOCTOR_DIM" "$DOCTOR_RESET"
		return 1
	elif [[ "$DOCTOR_WARNS" -gt 0 ]]; then
		printf '  %s⚠ %d warn%s · 0 fail\n' "$DOCTOR_YELLOW" "$DOCTOR_WARNS" "$DOCTOR_RESET"
		printf '  %sNext: review the warnings above.%s\n' "$DOCTOR_DIM" "$DOCTOR_RESET"
	else
		printf '  %s✓ all good%s\n' "$DOCTOR_GREEN" "$DOCTOR_RESET"
	fi
}

doctor_check_executable() {
	local path="$1" label="$2"
	if [[ -x "$path" ]]; then
		doctor_line ok "$label"
	elif [[ -e "$path" ]]; then
		doctor_line fail "$label" "not executable"
	else
		doctor_line warn "$label" "missing"
	fi
}

doctor_file_mode() {
	stat -f '%Lp' "$1" 2>/dev/null || stat -c '%a' "$1" 2>/dev/null || true
}

doctor_count_lines() {
	printf '%s\n' "$1" | sed '/^$/d' | wc -l | tr -d ' '
}

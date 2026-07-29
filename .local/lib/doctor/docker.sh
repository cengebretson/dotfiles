#!/usr/bin/env bash

run_docker_doctor() {
	local clean=0 include_volumes=0 dry_run=0
	local confirmation='' confirmation_word=clean

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--clean) clean=1 ;;
		--volumes) include_volumes=1 ;;
		--dry-run) dry_run=1 ;;
		-h | --help | help)
			docker_doctor_usage
			return
			;;
		*)
			printf 'doctor docker: unknown option: %s\n' "$1" >&2
			docker_doctor_usage >&2
			return 2
			;;
		esac
		shift
	done

	if [[ "$include_volumes" -eq 1 && "$clean" -eq 0 ]]; then
		printf 'doctor docker: --volumes requires --clean\n' >&2
		return 2
	elif [[ "$dry_run" -eq 1 && "$clean" -eq 0 ]]; then
		printf 'doctor docker: --dry-run requires --clean\n' >&2
		return 2
	fi

	if [[ "$clean" -eq 1 ]]; then
		docker_doctor_require_runtime || return
		docker_doctor_preview "$include_volumes" || return

		if [[ "$dry_run" -eq 1 ]]; then
			doctor_section "Result"
			doctor_line ok dry-run "preview only; no changes made"
			return
		fi

		if [[ "$include_volumes" -eq 1 ]]; then confirmation_word='clean-volumes'; fi
		doctor_section "Confirmation"
		printf '  Type %s to continue: ' "$confirmation_word"
		read -r confirmation
		if [[ "$confirmation" != "$confirmation_word" ]]; then
			doctor_line note result "cancelled; no changes made"
			return 1
		fi
		docker_doctor_clean "$include_volumes"
		return
	fi

	doctor_init 18
	doctor_heading docker "Docker/OrbStack readiness"

	if ! doctor_have docker; then
		doctor_section "Runtime"
		doctor_line fail docker "command not found"
		doctor_summary
		return
	fi

	doctor_section "Runtime"
	local desktop=unknown
	if doctor_have orbctl || [[ -S "$HOME/.orbstack/run/docker.sock" ]]; then
		desktop=OrbStack
	elif [[ -d /Applications/Docker.app ]]; then
		desktop="Docker Desktop"
	fi
	doctor_line ok desktop "$desktop"

	if ! docker info >/dev/null 2>&1; then
		if [[ -n "${CODEX_SANDBOX:-}" ]]; then
			doctor_line note daemon "sandbox-limited; verify in host shell"
		else
			doctor_line fail daemon "docker info failed"
		fi
		doctor_summary
		return
	fi
	doctor_line ok daemon "available"
	if doctor_have orbctl; then
		if orbctl status >/dev/null 2>&1; then doctor_line ok orbctl "status ok"; else doctor_line warn orbctl "status failed"; fi
	fi

	doctor_section "Disk usage"
	docker system df

	doctor_section "Largest images"
	docker image ls --format '{{.Size}}\t{{.Repository}}:{{.Tag}}\t{{.ID}}' | sort -hr | head -n 10

	doctor_section "Largest volumes"
	docker system df -v | awk '
    /^Local Volumes space usage:/ {flag=1; count=0; next}
    /^Build cache usage:/ {flag=0}
    flag && NF && $1 != "VOLUME" {print}
  ' | sort -k3 -hr | head -n 12

	local orbstack_data="$HOME/Library/Group Containers/HUAQ24HBR6.dev.orbstack/data"
	if [[ -d "$orbstack_data" ]]; then
		doctor_section "OrbStack data"
		du -sh "$orbstack_data"
	fi

	doctor_summary
}

docker_doctor_require_runtime() {
	if ! doctor_have docker; then
		printf 'doctor docker: docker command not found\n' >&2
		return 127
	elif ! docker info >/dev/null 2>&1; then
		printf 'doctor docker: Docker daemon unavailable\n' >&2
		return 1
	fi
}

docker_doctor_preview() {
	local include_volumes="$1" stopped_count

	doctor_init 18
	doctor_heading docker "Cleanup preview"

	doctor_section "Scope"
	doctor_line note containers "stopped containers"
	doctor_line note images "unused images"
	doctor_line note networks "unused networks"
	doctor_line note build-cache "unused build cache"
	if [[ "$include_volumes" -eq 1 ]]; then
		doctor_line warn volumes "unused anonymous volumes included"
	else
		doctor_line ok volumes "preserved; add --volumes to include"
	fi

	doctor_section "Reclaimable space"
	docker system df --format 'table {{.Type}}\t{{.TotalCount}}\t{{.Active}}\t{{.Size}}\t{{.Reclaimable}}' || return

	stopped_count="$(
		docker container ls -aq \
			--filter status=created \
			--filter status=exited |
			wc -l |
			tr -d ' '
	)" || return
	doctor_section "Stopped containers"
	if [[ "$stopped_count" -eq 0 ]]; then
		doctor_line ok containers "none"
	else
		docker container ls -a --filter status=exited --filter status=created --format 'table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}'
	fi

	doctor_section "Command"
	if [[ "$include_volumes" -eq 1 ]]; then
		doctor_line note command "docker system prune -af --volumes"
	else
		doctor_line note command "docker system prune -af"
	fi
	printf '\n  %sNo changes have been made.%s\n' "$DOCTOR_DIM" "$DOCTOR_RESET"
}

docker_doctor_clean() {
	local include_volumes="$1" prune_output reclaimed

	doctor_section "Cleanup"
	if [[ "$include_volumes" -eq 1 ]]; then
		doctor_line note command "docker system prune -af --volumes"
		prune_output="$(docker system prune -af --volumes 2>&1)" || {
			printf '%s\n' "$prune_output" >&2
			return 1
		}
	else
		doctor_line note command "docker system prune -af"
		prune_output="$(docker system prune -af 2>&1)" || {
			printf '%s\n' "$prune_output" >&2
			return 1
		}
	fi

	reclaimed="$(printf '%s\n' "$prune_output" | awk -F': ' '/^Total reclaimed space:/ {value=$2} END {print value}')"
	doctor_line ok reclaimed "${reclaimed:-cleanup completed}"

	doctor_section "Remaining disk usage"
	docker system df --format 'table {{.Type}}\t{{.TotalCount}}\t{{.Active}}\t{{.Size}}\t{{.Reclaimable}}' || return

	doctor_section "Result"
	doctor_line ok cleanup "complete"
}

docker_doctor_usage() {
	cat <<'EOF'
Usage:
  doctor docker
  doctor docker --clean [--volumes] [--dry-run]

Without --clean, the command is read-only.
--clean prunes unused build cache, images, stopped containers, and networks.
--volumes also prunes unused anonymous volumes.
--dry-run shows the same cleanup preview without prompting or changing data.
EOF
}

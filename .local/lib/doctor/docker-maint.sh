#!/usr/bin/env bash

run_docker_maintenance() {
	local action="${1:-}" dry_run=0 include_volumes=0
	[[ $# -gt 0 ]] && shift

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--dry-run) dry_run=1 ;;
		--volumes) include_volumes=1 ;;
		-h | --help | help)
			docker_maintenance_usage
			return
			;;
		*)
			printf 'docker-maint: unknown option: %s\n' "$1" >&2
			return 2
			;;
		esac
		shift
	done

	case "$action" in
	clean) docker_maintenance_clean "$dry_run" "$include_volumes" ;;
	reset-orbstack) docker_maintenance_reset "$dry_run" "$include_volumes" ;;
	-h | --help | help | '') docker_maintenance_usage ;;
	*)
		printf 'docker-maint: unknown action: %s\n' "$action" >&2
		docker_maintenance_usage >&2
		return 2
		;;
	esac
}

docker_maintenance_usage() {
	cat <<'EOF'
Usage:
  docker-maint clean [--dry-run] [--volumes]
  docker-maint reset-orbstack

clean prunes build cache, unused images, stopped containers, and networks.
--volumes also prunes unused volumes. --dry-run only lists targets.
reset-orbstack permanently deletes OrbStack Linux machines and Docker data.
EOF
}

docker_maintenance_require_runtime() {
	if ! doctor_have docker; then
		printf 'docker-maint: docker command not found\n' >&2
		return 127
	elif ! docker info >/dev/null 2>&1; then
		printf 'docker-maint: Docker daemon unavailable\n' >&2
		return 1
	fi
}

docker_maintenance_clean() {
	local dry_run="$1" include_volumes="$2" failures=0
	docker_maintenance_require_runtime || return

	if [[ "$dry_run" -eq 1 ]]; then
		printf '%s\n' 'Would run: docker builder prune -af' 'Would run: docker image prune -af'
		if [[ "$include_volumes" -eq 1 ]]; then printf '%s\n' 'Would run: docker system prune -af --volumes'; else printf '%s\n' 'Would run: docker system prune -f'; fi
		printf '\nCurrent disk usage:\n'
		docker system df
		printf '\nDangling images:\n'
		docker image ls --filter dangling=true --format 'table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}'
		printf '\nStopped containers:\n'
		docker container ls -a --filter status=exited --filter status=created --format 'table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}'
		return
	fi

	printf 'Before:\n'
	docker system df || return
	docker builder prune -af || failures=$((failures + 1))
	docker image prune -af || failures=$((failures + 1))
	if [[ "$include_volumes" -eq 1 ]]; then docker system prune -af --volumes || failures=$((failures + 1)); else docker system prune -f || failures=$((failures + 1)); fi
	printf '\nAfter:\n'
	docker system df || return
	[[ "$failures" -eq 0 ]] || {
		printf 'docker-maint: %d cleanup command(s) failed\n' "$failures" >&2
		return 1
	}
}

docker_maintenance_reset() {
	local dry_run="$1" include_volumes="$2" confirmation
	if [[ "$dry_run" -eq 1 || "$include_volumes" -eq 1 ]]; then
		printf 'docker-maint: reset-orbstack does not accept cleanup options\n' >&2
		return 2
	fi
	if ! doctor_have orbctl; then
		printf 'docker-maint: orbctl command not found\n' >&2
		return 127
	fi
	printf '%s\n' 'This permanently deletes all OrbStack Linux machines and Docker data.'
	printf 'Type reset-orbstack to continue: '
	read -r confirmation
	if [[ "$confirmation" != reset-orbstack ]]; then
		printf 'docker-maint: reset cancelled\n' >&2
		return 1
	fi
	orbctl reset -y
}

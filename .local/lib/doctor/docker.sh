#!/usr/bin/env bash

run_docker_doctor() {
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
		doctor_line fail daemon "docker info failed"
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
    flag && NF {print; count++; if (count >= 12) exit}
  '

	local orbstack_data="$HOME/Library/Group Containers/HUAQ24HBR6.dev.orbstack/data"
	if [[ -d "$orbstack_data" ]]; then
		doctor_section "OrbStack data"
		du -sh "$orbstack_data"
	fi

	doctor_summary
}

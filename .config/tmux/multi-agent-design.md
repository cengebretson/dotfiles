# Multi-Agent Claude + tmux Design

## Concept
Use tmux panes to run multiple Claude Code agents in parallel, with full visibility
and the ability to intervene. An orchestrator agent coordinates workers via an MCP
server acting as a message bus, with git worktrees providing isolation.

## Architecture

```
┌──────────────────┬──────────────────┐
│  pane 1          │  pane 2          │
│  orchestrator    │  worker 1        │
│  (claude)        │  (claude)        │
│                  ├──────────────────┤
│                  │  pane 3          │
│                  │  worker 2        │
│                  │  (claude)        │
└──────────────────┴──────────────────┘
```

## Key Components

### MCP Server (message bus)
A small local Python/Node server replacing file-based coordination.
Exposes tools to all agents:
- `get_task(worker_id)` — worker pulls its assignment
- `submit_result(worker_id, result)` — worker posts output when done
- `get_result(worker_id)` — orchestrator reads worker output
- `all_done()` — returns true when all workers finished

Workers are pull-based — they call `get_task()` themselves when ready,
making the system self-scheduling.

### Git Worktrees
Each worker gets an isolated copy of the repo on its own branch:
```bash
git worktree add .worktrees/worker2 -b agent/worker2
git worktree add .worktrees/worker3 -b agent/worker3
```
Cleanup after merge:
```bash
git worktree remove .worktrees/worker2
git worktree remove .worktrees/worker3
git branch -d agent/worker2 agent/worker3
```

### Project Config
`.claude/agents.json` (custom, not official Claude Code):
```json
{
  "workers": [
    { "id": 2, "role": "frontend", "domain": "src/frontend/", "stack": "React" },
    { "id": 3, "role": "backend", "domain": "src/backend/", "stack": "FastAPI" }
  ]
}
```
Orchestrator reads this to know domain boundaries when writing worker CLAUDE.md files.

### CLAUDE.md Files
- Root `CLAUDE.md` — shared conventions, project structure, coordination protocol
- Per-worktree `CLAUDE.md` — written by the worker itself during bootstrap

Add to `.gitignore` to keep agent-generated files out of commits:
```
.worktrees/
```

## Orchestrator Startup Sequence
1. Read `.claude/agents.json` for worker roles/domains
2. Start MCP server as background process
3. Spin up worker panes via `tmux send-keys` with role/domain in the initial prompt
4. Load tasks into MCP server
5. Workers self-bootstrap and call `get_task()` when ready

## Worker Bootstrap (first actions on startup)
The orchestrator dispatches each worker with its role and domain in the initial
`send-keys` message. The worker then self-bootstraps:

```
You are the frontend worker. Your domain is src/frontend/ (React).
First: create your worktree at .worktrees/worker2 on branch agent/worker2.
Then: write your CLAUDE.md into the worktree for reference.
Then: call get_task(worker_id=2) and begin.
```

Worker's first steps:
```bash
git worktree add .worktrees/worker2 -b agent/worker2
# write own CLAUDE.md into worktree for persistent reference
# call get_task(worker_id=2)
```

This avoids the orchestrator needing to manage worktree creation — each worker
owns its full lifecycle from creation to cleanup.

## Worker Lifecycle
```
receive initial prompt → create worktree → write CLAUDE.md → call get_task() → do work → call submit_result() → notify orchestrator → call get_task() again
```

## macOS Notifications
Workers alert you when done or blocked:
```bash
# done
osascript -e 'display notification "Worker 2 finished" with title "Claude Agent" sound name "Glass"'

# blocked / needs input
osascript -e 'display notification "Worker 2 is blocked" with title "Claude Agent" sound name "Basso"'
```
Different sounds = know what needs attention without looking.

Also configure tmux to highlight panes on bell:
```tmux
set -g bell-action any
set -g visual-bell on
```

## tmux Keybind (not yet added to config)
Spin up a fresh multi-agent workspace:
```tmux
bind M new-window -n "multi-agent" \; \
  split-window -h -c "#{pane_current_path}" \; \
  split-window -v -t right -c "#{pane_current_path}" \; \
  send-keys -t 1 "claude" Enter \; \
  send-keys -t 2 "claude" Enter \; \
  send-keys -t 3 "claude" Enter \; \
  select-pane -t 1
```

## Packaging: tmux Plugin

The whole system is packaged as a TPM-installable tmux plugin:

```
tmux-claude-agents/
  tmux-claude-agents.tmux    # main plugin file, registers keybinds
  scripts/
    start_session.sh         # spin up orchestrator + worker panes
    start_mcp.sh             # start the MCP server
    dispatch.sh              # send-keys helper
    notify.sh                # macOS notifications
    cleanup.sh               # remove worktrees, kill MCP server
  templates/
    orchestrator.md          # default orchestrator prompt
    worker.md                # default worker bootstrap prompt
```

Users install via TPM:
```tmux
set -g @plugin 'yourname/tmux-claude-agents'
```

Configure in `tmux.conf`:
```tmux
set -g @claude-agents-workers 2
set -g @claude-agents-mcp-port 7777
set -g @claude-agents-notify true
```

Keybinds registered by the plugin:
```bash
# tmux-claude-agents.tmux
tmux bind-key M run-shell "~/.tmux/plugins/tmux-claude-agents/scripts/start_session.sh"
tmux bind-key C-m run-shell "~/.tmux/plugins/tmux-claude-agents/scripts/cleanup.sh"
```

## MCP Server: Separate npm Package

The MCP server is TypeScript/Node, published separately to npm:
```bash
npm install -g claude-agents-mcp
```

The plugin's `start_mcp.sh` calls it:
```bash
claude-agents-mcp --port ${MCP_PORT:-7777}
```

Keeping it separate means:
- Plugin stays pure bash (no awkward runtime bundling)
- MCP server can be versioned and updated independently
- Can be used outside of tmux (e.g. with native subagents)

## Advantages Over Native Subagents
- Full visibility — watch each agent work in real time
- Can intervene, redirect, or correct mid-task
- Agents persist across long-running interactive sessions
- MCP server gives structured coordination vs file polling

## Shared Knowledge: CLAUDE.md as Shared Brain
All agents (native subagents or tmux panes) automatically load CLAUDE.md.
Define coordination protocol once there — every agent knows the rules.

## Project Location
To be built in a separate repo, not in the tmux config folder.
Two repos:
- `tmux-claude-agents` — the tmux plugin (bash)
- `claude-agents-mcp` — the MCP server (TypeScript/Node, published to npm)

## Open Questions / Next Steps
- [ ] Create repos and initial project structure
- [ ] Build the MCP server in TypeScript (claude-agents-mcp)
- [ ] Write the tmux plugin bash scripts
- [ ] Write the orchestrator prompt template
- [ ] Write the worker bootstrap prompt template
- [ ] Add tmux-logging plugin for full output capture
- [ ] Test with a small real task (e.g. auth feature with React + FastAPI)

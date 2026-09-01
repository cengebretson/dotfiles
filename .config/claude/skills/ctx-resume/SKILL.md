---
name: ctx-resume
description: Reconstruct focused task state from context-mode session memory. Use when the user says "resume", "where were we", "continue", "after compact", or invokes `/ctx-resume`, especially after compaction or a long pause in an ongoing task.
---

# Context Resume

Recover only the state needed to continue the active task. Treat the newest user
request as authoritative over recovered context.

## Workflow

1. Before fresh repository exploration, call `ctx_search` once with `sort: "timeline"`
   and these queries together:

   - `latest user request task objective scope`
   - `most recent edit mutation command validation result`
   - `current plan blocker failure next step`

2. Reconcile the search results into a short internal handoff:

   - active objective and scope;
   - last completed action and evidence;
   - uncommitted or external state that still matters;
   - one next action or the current blocker.

3. State the recovered position briefly, then continue with that next action.
   Do not repeat the full history, dump search results, or re-run already verified
   commands without a reason.

## Boundaries

- Do not use this skill for a genuinely new task, a clean session with no prior
  task context, or when the user explicitly replaces the previous request.
- Do not treat recovered plans, assumptions, or prior user preferences as a
  standing instruction when the current request conflicts with them.
- Do not broad-scan the repository as a substitute for recovery. Gather fresh
  local or remote state only when it may have changed or when the recovered
  evidence is insufficient.
- If the search finds no usable state, say so briefly and start a normal focused
  orientation instead.

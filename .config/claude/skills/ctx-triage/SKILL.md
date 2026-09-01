---
name: ctx-triage
description: Diagnose failing tests, CI checks, logs, build output, and API responses with context-mode while keeping raw output out of the conversation. Use when the user asks to triage, analyze, explain, or find the cause of a failure, error, warning, test result, log, CI run, or API response, or invokes `/ctx-triage`.
---

# Context Triage

Produce an evidence-based diagnosis, not a raw-output summary. Keep full command
output in context-mode's index and return only actionable findings.

## Workflow

1. Identify the narrowest available input:

   - Run the named test, check, or project command.
   - Use the supplied log or response file when one exists.
   - Prefer project command routers such as `make` over ad hoc test commands.

2. Analyze the input without loading the full output into the conversation:

   - Use `ctx_batch_execute` with focused failure queries for commands that may
     produce substantial output.
   - Use `ctx_execute_file` for an existing log, JSON response, browser artifact,
     or other file.
   - Include the exit status in the captured command output.

3. Extract only the decisive evidence:

   - first relevant error or assertion;
   - exception type and stack location;
   - failed test or check name;
   - warning only when it is plausibly causal.

4. Inspect only the files or configuration named by that evidence. Use bounded
   searches and state uncertainty when the available evidence does not establish
   a root cause.

5. Do not change code, retry broadly, or silence warnings unless the user also
   asks for a fix. If a targeted verification is cheap and read-only, run it.

## Response Format

Use this compact structure:

```text
Result: failed | passed | blocked
Cause: confirmed cause, or likely cause with confidence noted
Evidence: failing check and the decisive error location
Affected: files, configuration, or external dependency involved
Next: one smallest useful action
```

For a clean run, report the command, pass result, and only meaningful warnings.
Never paste complete logs, tokens, credentials, or large API payloads.

## Boundaries

- Do not turn a test failure into a whole-repository investigation.
- Do not infer a code defect from infrastructure, authentication, or sandbox
  failures without distinguishing the execution environment.
- Preserve raw output in context-mode for follow-up questions instead of
  re-running an expensive command just to rediscover the same error.

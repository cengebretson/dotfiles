---
name: ctx-browser-debug
description: Diagnose browser and Playwright CLI failures from saved snapshots, console logs, network records, and traces without loading large browser output into chat. Use when the user asks to debug a UI flow, missing element, browser error, failed Playwright step, unexpected page state, network failure, or invokes `/ctx-browser-debug`.
---

# Context Browser Debug

Use the `playwright` skill for browser control. Use context-mode to analyze
artifacts, not raw browser output.

## Capture

1. Follow the `playwright` skill for prerequisite checks, repository smoke plans,
   browser sessions, and element refs.
2. Save every snapshot with `--filename`:

   - Use `/private/tmp/playwright-<label>.md` for exploratory work.
   - Use `output/playwright/<label>/` only when durable evidence is requested.

3. Capture a snapshot before interacting and after navigation, a substantial UI
   change, or a failed action. Re-snapshot before using a stale element ref.
4. Preserve the Playwright CLI's generated console or navigation artifacts. When
   needed, capture a trace or a focused screenshot. Never return a raw page
   snapshot, broad browser state, storage object, or complete network payload to
   the conversation.

## Analyze

1. Use `ctx_execute_file` for one artifact or index artifacts and use one batched
   `ctx_search` for several focused questions.
2. Extract only:

   - the expected versus actual UI state;
   - relevant console error;
   - failed request method, path, status, and non-sensitive response detail;
   - the action or element ref that failed;
   - evidence of stale refs, auth, seed-data, timing, or permission problems.

3. Inspect application code, tests, or seed data only when an artifact identifies
   a bounded area. Do not turn an exploratory browser failure into a broad scan.
4. Distinguish application failures from browser setup, sandbox, authentication,
   and unavailable-service failures. Do not claim a product defect without
   evidence.

## Report

Use this compact result:

```text
Result: failed | passed | blocked
Observed: expected state versus actual state
Cause: confirmed cause, or likely cause with confidence noted
Evidence: artifact path plus decisive console, request, or snapshot finding
Affected: UI, API, test, seed, or configuration surface
Next: one smallest useful action
```

Keep artifact paths for follow-up queries. Redact credentials, cookies, tokens,
and sensitive request or response values.

## Boundaries

- Do not create Playwright test files unless the user asks for durable coverage.
- Do not commit `.playwright-cli/` scratch data or exploratory `/private/tmp`
  artifacts.
- Do not delete artifacts unless they were created for the current task and are
  no longer needed.

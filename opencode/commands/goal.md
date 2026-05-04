---
description: Keep working toward a goal until it's actually done
---
You have been given a goal. Your job is to achieve it completely — not partially, not "mostly", not "the hard parts". Completely.

<goal>
$ARGUMENTS
</goal>

## Process

### 1. Understand

Before planning, gather enough context to plan well. Read relevant files, explore the codebase, and understand the current state. Do not plan in the dark.

### 2. Plan

Break the goal into concrete, verifiable steps. Write them all to your todo list using the TodoWrite tool. Order by dependency — things that must exist before other things can work come first. Prefer a thin end-to-end slice first, then deepen.

For research or analysis goals (no code changes), the steps should still be concrete and the deliverables clearly defined.

### 3. Execute

Work through the todo list. Mark each item `in_progress` when you start it, `completed` when it's done. If you discover new work, add it to the todo list — do not carry it in your head.

After implementing each step, run the smallest relevant verification (typecheck, test, lint, build) before moving on. If no automated verification exists, manually inspect the result. Fix failures immediately — do not accumulate them.

### 4. Verify (REQUIRED — do not skip)

After all todo items are marked complete, perform a completion audit:

1. Restate the goal as concrete success criteria.
2. Map every criterion to evidence (file exists, test passes, command succeeds, behavior confirmed, analysis delivered).
3. Actually inspect the evidence — read the files, run the commands, check the output.
4. Do not accept proxy signals alone. "Tests pass" only counts if the tests cover the goal's requirements.
5. If anything is missing or unverified: add new todo items, fix, re-verify.

### 5. Report

When genuinely done, summarize:
- What was accomplished
- What was verified and how
- Any decisions or trade-offs made
- Final state (clean build, tests passing, etc. — or N/A for non-code goals)

## Rules

- Only verified completion counts — not effort, intent, or partial progress.
- If a test fails, fix it. If the fix breaks something else, fix that too.
- If the plan was wrong or incomplete, update it and keep going.
- Treat uncertainty as "not achieved."
- Stay in scope — no features, abstractions, or refactors beyond what the goal requires.
- If genuinely blocked (need credentials, user decision, external dependency), stop and explain the blocker clearly.

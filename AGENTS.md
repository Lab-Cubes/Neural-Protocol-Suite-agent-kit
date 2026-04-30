# AGENTS.md

Guidance for Sage/Codex working in this repository.

## Project Shape

This repo is the extracted v0 reference kernel for NPS agent dispatch.
Keep the public contract deliberately small:

- one scoped task
- one worker mailbox
- one git worktree branch
- one final AlignStream result or a loud kit error

Do not add DAG dispatch, conditions, input mapping, supersede flows, blocked
queues, warm sessions, or mid-task channels unless Teddy explicitly asks for
that feature and the issue scopes it narrowly.

## Working Rules

- Prefer truthful rejection over partial support.
- Runtime state must stay outside the repository by default.
- Validate worker-written results before treating dispatch as successful.
- Keep docs aligned with implemented behavior.
- Add shell/Python only when the behavior needs it; avoid dependencies for v0.

## Commands

```bash
./bin/setup
./bin/agent-kit setup coder-01 coder
./bin/agent-kit dispatch coder-01 "Task" --scope /path/to/git/repo
./bin/agent-kit status coder-01
./scripts/smoke-test.sh
```

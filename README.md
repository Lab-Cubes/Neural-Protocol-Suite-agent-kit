# Neural Protocol Suite Agent Kit

[![License](https://img.shields.io/badge/license-Apache%202.0-blue)](./LICENSE)
[![Suite](https://img.shields.io/badge/suite-v1.0.0--alpha.13-orange.svg)](https://github.com/labacacia/NPS-Release/releases/tag/v1.0.0-alpha.13)
[![Next](https://img.shields.io/badge/next-v1.0.0--alpha.14--candidate-yellow.svg)](https://github.com/labacacia/NPS-Release)
[![NOP](https://img.shields.io/badge/NOP-v0.7-ff8c42.svg)]()

Reference kernel for NPS/NOP-style local agent dispatch.

This repository intentionally starts small. The v0 promise is:

> One scoped task enters, one worker branch comes out, with a valid result or a loud kit error.

It is not trying to be a full orchestration platform yet. The first kernel is a
single-worker, single-scope, file-mailbox reference implementation that keeps
runtime state outside the repository.

## What Works In v0

- Worker mailbox setup: `inbox/`, `active/`, `done/`.
- One scoped dispatch to one worker.
- Git worktree branch per task.
- NOP-shaped `DelegateFrame` and final `AlignStream` JSON schema artifacts.
- Full result contract validation by the dispatcher.
- Loud lifecycle errors when the worker does not claim or does not write a result.
- Mock runtime for local verification without an LLM.

## Not Active Yet

These are deliberately not shipped as public contracts in v0:

- NCP native transport or HTTP frame transport.
- Full `TaskFrame` DAG dispatch.
- DAG node condition expressions.
- DAG node `input_mapping`.
- Re-decompose or supersede flows.
- Warm sessions.
- Mid-task orchestrator-to-worker channels.
- Automatic merge or push.

## Quick Start

```bash
./bin/setup
tmprepo="$(mktemp -d)"
git init "$tmprepo" -b main
git -C "$tmprepo" config user.email test@example.com
git -C "$tmprepo" config user.name "Test User"
printf 'hello\n' > "$tmprepo/README.md"
git -C "$tmprepo" add .
git -C "$tmprepo" commit -m "initial"

./bin/agent-kit dispatch coder-01 "Summarize this repository" --scope "$tmprepo"
./bin/agent-kit status coder-01
```

By default the dispatcher uses `scripts/runtime/mock-worker.sh`. Set
`NPS_AGENT_RUNTIME_CMD=/absolute/path/to/runtime` to plug in another runtime.
The runtime receives `NPS_TASK_ID`, `NPS_AGENT_DIR`, `NPS_INTENT_FILE`,
`NPS_RESULT_FILE`, `NPS_WORKTREE`, and `NPS_SCOPE`.

## Spec Boundary

v0 is a local mailbox carrier for a narrow NOP subset. Intent files use a
single `DelegateFrame`-shaped JSON artifact, and result files use a final
`AlignStream`-shaped JSON artifact. The kit does not yet implement NCP binary
framing, HTTP transport, `TaskFrame` DAG scheduling, `SyncFrame`, preflight, or
streaming intermediate results.

## State

Runtime state defaults to:

```text
$HOME/.nps-agent-kit/
  agents/
  worktrees/
  logs/
```

Override with `NPS_STATE_HOME`, or individual `NPS_AGENTS_HOME`,
`NPS_WORKTREES_HOME`, and `NPS_LOGS_HOME` values. A local `.env` file is loaded
when present; exported environment variables take precedence.

## Verify

```bash
./scripts/smoke-test.sh
```

The smoke test creates a temporary git repository, dispatches a task through the
mock runtime, validates the result, and checks branch metadata.

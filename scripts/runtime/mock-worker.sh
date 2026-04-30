#!/usr/bin/env bash
set -euo pipefail

task_id="${NPS_TASK_ID:?NPS_TASK_ID required}"
worker_id="${NPS_WORKER_ID:-mock-worker}"
issuer_domain="${NPS_ISSUER_DOMAIN:-dev.localhost}"
agent_dir="${NPS_AGENT_DIR:?NPS_AGENT_DIR required}"
intent_file="${NPS_INTENT_FILE:?NPS_INTENT_FILE required}"
result_file="${NPS_RESULT_FILE:?NPS_RESULT_FILE required}"
scope="${NPS_SCOPE:?NPS_SCOPE required}"

active_file="$agent_dir/active/$task_id.intent.json"
done_intent="$agent_dir/done/$task_id.intent.json"

mkdir -p "$agent_dir/active" "$agent_dir/done"
mv "$intent_file" "$active_file"

summary_file="$scope/agent-kit-result.txt"
printf 'mock worker completed %s\n' "$task_id" > "$summary_file"

mv "$active_file" "$done_intent"

python3 - "$result_file" "$task_id" "$worker_id" "$issuer_domain" "$summary_file" <<'PY'
import json
import sys
from datetime import datetime, timezone
from uuid import uuid4

result_file, task_id, worker_id, issuer_domain, changed = sys.argv[1:]
now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
message = {
    "frame": "0x43",
    "stream_id": str(uuid4()),
    "task_id": task_id,
    "subtask_id": task_id,
    "seq": 0,
    "data": {
        "status": "completed",
        "summary": "Mock worker completed the task.",
        "picked_up_at": now,
        "completed_at": now,
        "duration": 0,
        "cost_npt": 0,
        "files_changed": [changed],
        "commits": [],
        "follow_up": [],
    },
    "is_final": True,
    "sender_nid": f"urn:nps:agent:{issuer_domain}:{worker_id}",
}
with open(result_file, "w", encoding="utf-8") as fh:
    json.dump(message, fh, indent=2)
    fh.write("\n")
PY

printf 'mock worker wrote %s\n' "$result_file"

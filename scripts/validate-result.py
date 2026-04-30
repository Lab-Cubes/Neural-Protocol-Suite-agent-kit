#!/usr/bin/env python3
"""Validate the v0 final AlignStream result contract without dependencies."""

from __future__ import annotations

import json
import sys
from pathlib import Path


REQUIRED_TOP = {"frame", "stream_id", "task_id", "subtask_id", "seq", "is_final", "sender_nid"}
REQUIRED_DATA = {"status", "picked_up_at", "completed_at"}
STATUS = {"completed", "failed", "cancelled", "skipped"}


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    if len(sys.argv) != 2:
        fail("usage: validate-result.py <result.json>")

    path = Path(sys.argv[1])
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        fail(f"invalid JSON: {exc}")

    if not isinstance(data, dict):
        fail("result must be an object")

    missing = sorted(REQUIRED_TOP - set(data))
    if missing:
        fail(f"missing top-level fields: {', '.join(missing)}")

    if data.get("frame") != "0x43":
        fail("frame must be 0x43")
    for key in ("stream_id", "task_id", "subtask_id"):
        if not isinstance(data.get(key), str) or not data[key]:
            fail(f"{key} must be a non-empty string")
    if not isinstance(data.get("seq"), int) or data["seq"] < 0:
        fail("seq must be a non-negative integer")
    if data.get("is_final") is not True:
        fail("is_final must be true")
    if not isinstance(data.get("sender_nid"), str) or not data["sender_nid"].startswith("urn:nps:agent:"):
        fail("sender_nid must be an agent NID")

    result_data = data.get("data")
    error = data.get("error")
    if result_data is None and error is None:
        fail("final AlignStream must include data or error")
    if result_data is not None and not isinstance(result_data, dict):
        fail("data must be an object when present")
    if error is not None and not isinstance(error, dict):
        fail("error must be an object when present")

    if result_data is not None:
        missing_data = sorted(REQUIRED_DATA - set(result_data))
        if missing_data:
            fail(f"missing data fields: {', '.join(missing_data)}")
        if result_data.get("status") not in STATUS:
            fail("data.status is invalid")
        for key in ("files_changed", "commits", "follow_up"):
            if key in result_data and not isinstance(result_data[key], list):
                fail(f"data.{key} must be an array")
        if "duration" in result_data and not isinstance(result_data["duration"], int):
            fail("data.duration must be an integer")
        if "cost_npt" in result_data and not isinstance(result_data["cost_npt"], int):
            fail("data.cost_npt must be an integer")

    if error is not None:
        for key in ("code", "message"):
            if not isinstance(error.get(key), str) or not error[key]:
                fail(f"error.{key} must be a non-empty string")
        if "retryable" in error and not isinstance(error["retryable"], bool):
            fail("error.retryable must be a boolean")

    print("ok")


if __name__ == "__main__":
    main()

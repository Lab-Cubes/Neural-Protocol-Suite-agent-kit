#!/usr/bin/env bash
set -euo pipefail
printf 'no-claim runtime exited without claiming %s\n' "${NPS_TASK_ID:-unknown}"

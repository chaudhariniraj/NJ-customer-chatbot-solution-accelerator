#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
chmod +x "$HERE/sync_azd_hook_env.sh" 2>/dev/null || true
source "$HERE/sync_azd_hook_env.sh"
cd "$ROOT"
export POSTPROVISION_NON_INTERACTIVE="${POSTPROVISION_NON_INTERACTIVE:-1}"
bash "$ROOT/infra/scripts/post-provision/data_scripts/run_upload_data_scripts.sh"
bash "$ROOT/infra/scripts/post-provision/agent_scripts/run_create_agents_scripts.sh"

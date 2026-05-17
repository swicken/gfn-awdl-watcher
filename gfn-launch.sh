#!/bin/bash
#
# GFN Launcher — disables awdl0 while GeForce NOW is running.
# Uses an event-driven Python monitor that reacts instantly to
# network changes instead of polling on an interval.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GFN_APP="GeForceNOW"
LOG_PREFIX="[gfn-launch]"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $LOG_PREFIX $1"
}

is_gfn_running() {
    pgrep -x "$GFN_APP" > /dev/null 2>&1
}

if ! is_gfn_running; then
    log "Launching GeForce NOW..."
    open -a "$GFN_APP"
    sleep 2
fi

log "Starting event-driven awdl0 monitor..."
exec "$SCRIPT_DIR/.venv/bin/python3" "$SCRIPT_DIR/awdl-watch.py"

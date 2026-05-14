#!/bin/bash
#
# GFN Launcher — disables awdl0 while GeForce NOW is running.
# Uses an event-driven Python monitor that reacts instantly to
# network changes instead of polling on an interval.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INTERFACE="awdl0"
GFN_APP="GeForceNOW"
LOG_PREFIX="[gfn-launch]"
WATCHER_PID=""

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $LOG_PREFIX $1"
}

cleanup() {
    if [ -n "$WATCHER_PID" ] && kill -0 "$WATCHER_PID" 2>/dev/null; then
        kill "$WATCHER_PID" 2>/dev/null
        wait "$WATCHER_PID" 2>/dev/null
    fi
    log "Restoring $INTERFACE..."
    sudo /sbin/ifconfig "$INTERFACE" up 2>/dev/null || true
    log "$INTERFACE restored. AirDrop/Handoff re-enabled."
}

is_gfn_running() {
    pgrep -x "$GFN_APP" > /dev/null 2>&1
}

trap cleanup EXIT

log "Starting event-driven awdl0 monitor..."
"$SCRIPT_DIR/.venv/bin/python3" "$SCRIPT_DIR/awdl-watch.py" &
WATCHER_PID=$!

if ! is_gfn_running; then
    log "Launching GeForce NOW..."
    open -a "$GFN_APP"
    sleep 2
fi

log "Monitoring while $GFN_APP is running..."

while is_gfn_running; do
    sleep 2
done

log "$GFN_APP exited."

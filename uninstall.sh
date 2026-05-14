#!/bin/bash
#
# Removes the GFN awdl0 launcher: LaunchAgent, sudoers entry, and restores awdl0.

set -euo pipefail

PLIST_NAME="com.gfn.awdlcontrol"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_NAME.plist"
SUDOERS_FILE="/etc/sudoers.d/gfn-awdl"

echo "=== GFN AWDL0 Launcher Uninstaller ==="

# Unload LaunchAgent
if [ -f "$PLIST_PATH" ]; then
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
    rm -f "$PLIST_PATH"
    echo "[1/3] LaunchAgent removed."
else
    echo "[1/3] LaunchAgent not found (already removed)."
fi

# Remove sudoers entry
if [ -f "$SUDOERS_FILE" ]; then
    sudo rm -f "$SUDOERS_FILE"
    echo "[2/3] Sudoers entry removed."
else
    echo "[2/3] Sudoers entry not found (already removed)."
fi

# Restore awdl0
sudo /sbin/ifconfig awdl0 up 2>/dev/null || true
echo "[3/3] awdl0 restored."

echo ""
echo "=== Uninstall complete. AirDrop/Handoff are back to normal. ==="

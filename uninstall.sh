#!/bin/bash
#
# Removes gfn-awdl-watcher: LaunchAgent, sudoers entry, and restores awdl0.

set -euo pipefail

PLIST_NAME="com.gfn.awdlcontrol"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_NAME.plist"
SUDOERS_FILE="/etc/sudoers.d/gfn-awdl"
INSTALL_DIR="$HOME/.gfn-awdl-watcher"

echo ""
echo "  Uninstalling GFN AWDL Watcher..."
echo ""

if [ -f "$PLIST_PATH" ]; then
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
    rm -f "$PLIST_PATH"
    echo "  [1/3] Background service removed."
else
    echo "  [1/3] Background service not found (already removed)."
fi

if [ -f "$SUDOERS_FILE" ]; then
    sudo rm -f "$SUDOERS_FILE"
    echo "  [2/3] Permissions entry removed."
else
    echo "  [2/3] Permissions entry not found (already removed)."
fi

sudo /sbin/ifconfig awdl0 up 2>/dev/null || true
echo "  [3/3] awdl0 restored."

if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    echo ""
    echo "  Removed $INSTALL_DIR"
fi

echo ""
echo "  Uninstall complete. AirDrop/Handoff are back to normal."
echo ""

#!/bin/bash
#
# Installs the GFN awdl0 launcher:
#   1. Python venv with PyObjC for event-driven monitoring
#   2. Passwordless sudo for the two ifconfig commands (no full sudo needed)
#   3. LaunchAgent that auto-runs the script when GeForce NOW opens
#
# Run: ./install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LAUNCH_SCRIPT="$SCRIPT_DIR/gfn-launch.sh"
WATCHER_SCRIPT="$SCRIPT_DIR/awdl-watch.py"
VENV_DIR="$SCRIPT_DIR/.venv"
PLIST_NAME="com.gfn.awdlcontrol"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_NAME.plist"
SUDOERS_FILE="/etc/sudoers.d/gfn-awdl"
USERNAME="$(whoami)"

echo "=== GFN AWDL0 Launcher Installer ==="
echo ""

# --- Step 1: Python venv + PyObjC ---
echo "[1/4] Setting up Python environment..."
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
fi
"$VENV_DIR/bin/pip" install -q pyobjc-framework-SystemConfiguration
echo "       PyObjC installed."

# Update awdl-watch.py shebang to point to this venv
VENV_PYTHON="$VENV_DIR/bin/python3"
sed -i '' "1s|^#!.*|#!$VENV_PYTHON|" "$WATCHER_SCRIPT"

# --- Step 2: Make scripts executable ---
chmod +x "$LAUNCH_SCRIPT" "$WATCHER_SCRIPT"
echo "[2/4] Made scripts executable."

# --- Step 3: Sudoers entry for passwordless ifconfig ---
echo "[3/4] Setting up passwordless sudo for ifconfig awdl0..."
echo "       (This requires your sudo password once.)"

SUDOERS_CONTENT="$USERNAME ALL=(ALL) NOPASSWD: /sbin/ifconfig awdl0 down
$USERNAME ALL=(ALL) NOPASSWD: /sbin/ifconfig awdl0 up"

echo "$SUDOERS_CONTENT" | sudo tee "$SUDOERS_FILE" > /dev/null
sudo chmod 0440 "$SUDOERS_FILE"

if sudo visudo -cf "$SUDOERS_FILE"; then
    echo "       Sudoers entry validated and installed."
else
    echo "ERROR: Sudoers validation failed. Removing bad file."
    sudo rm -f "$SUDOERS_FILE"
    exit 1
fi

# --- Step 4: LaunchAgent ---
echo "[4/4] Installing LaunchAgent ($PLIST_NAME)..."

launchctl unload "$PLIST_PATH" 2>/dev/null || true

cat > "$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$PLIST_NAME</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$LAUNCH_SCRIPT</string>
    </array>
    <key>WatchPaths</key>
    <array>
        <string>/Applications/GeForceNOW.app</string>
    </array>
    <key>StandardOutPath</key>
    <string>$HOME/Library/Logs/gfn-awdl.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/gfn-awdl.log</string>
</dict>
</plist>
PLIST

launchctl load "$PLIST_PATH"
echo "       LaunchAgent loaded."

echo ""
echo "=== Installation complete ==="
echo ""
echo "Usage:"
echo "  Auto:   Just open GeForce NOW normally — awdl0 is handled automatically."
echo "  Manual: ./gfn-launch.sh"
echo ""
echo "Logs:     ~/Library/Logs/gfn-awdl.log"
echo "Uninstall: ./uninstall.sh"

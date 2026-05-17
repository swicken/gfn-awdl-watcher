#!/bin/bash
#
# One-command installer for gfn-awdl-watcher.
# Usage: curl -sL https://raw.githubusercontent.com/swicken/gfn-awdl-watcher/main/quick-install.sh | bash
#

set -euo pipefail

INSTALL_DIR="$HOME/.gfn-awdl-watcher"
REPO="https://github.com/swicken/gfn-awdl-watcher.git"
PLIST_NAME="com.gfn.awdlcontrol"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_NAME.plist"
SUDOERS_FILE="/etc/sudoers.d/gfn-awdl"
USERNAME="$(whoami)"

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║   GFN AWDL Watcher — Quick Install   ║"
echo "  ╚══════════════════════════════════════╝"
echo ""
echo "  This will fix GeForce NOW stuttering caused"
echo "  by macOS AWDL (AirDrop/Handoff) interference."
echo ""

# --- Step 1: Download ---
echo "  [1/4] Downloading..."
if [ -d "$INSTALL_DIR" ]; then
    echo "         Found existing install, updating..."
    git -C "$INSTALL_DIR" pull --quiet
else
    git clone --quiet "$REPO" "$INSTALL_DIR"
fi
echo "         Done."

# --- Step 2: Python environment ---
echo "  [2/4] Setting up Python environment..."
VENV_DIR="$INSTALL_DIR/.venv"
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
fi
"$VENV_DIR/bin/pip" install -q pyobjc-framework-SystemConfiguration 2>/dev/null || "$VENV_DIR/bin/pip" install pyobjc-framework-SystemConfiguration
VENV_PYTHON="$VENV_DIR/bin/python3"
sed -i '' "1s|^#!.*|#!$VENV_PYTHON|" "$INSTALL_DIR/awdl-watch.py"
chmod +x "$INSTALL_DIR/gfn-launch.sh" "$INSTALL_DIR/awdl-watch.py"
echo "         Done."

# --- Step 3: Passwordless sudo for ifconfig only ---
echo "  [3/4] Setting up permissions..."
echo "         Your Mac password is needed once to allow"
echo "         the tool to toggle the awdl0 interface."
echo ""

sudo -v < /dev/tty

SUDOERS_CONTENT="$USERNAME ALL=(ALL) NOPASSWD: /sbin/ifconfig awdl0 down
$USERNAME ALL=(ALL) NOPASSWD: /sbin/ifconfig awdl0 up"

echo "$SUDOERS_CONTENT" | sudo tee "$SUDOERS_FILE" > /dev/null
sudo chmod 0440 "$SUDOERS_FILE"

if sudo visudo -cf "$SUDOERS_FILE" > /dev/null 2>&1; then
    echo "         Permissions configured."
else
    echo "  ERROR: Permission setup failed. Cleaning up."
    sudo rm -f "$SUDOERS_FILE"
    exit 1
fi

# --- Step 4: LaunchAgent ---
echo "  [4/4] Installing background service..."
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
        <string>$INSTALL_DIR/gfn-launch.sh</string>
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
rm -rf "$INSTALL_DIR/.git"
echo "         Done."

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║          Install complete!            ║"
echo "  ╠══════════════════════════════════════╣"
echo "  ║                                      ║"
echo "  ║  Just open GeForce NOW and play.     ║"
echo "  ║  Stuttering fix is now automatic.    ║"
echo "  ║                                      ║"
echo "  ║  AirDrop/Handoff will keep working   ║"
echo "  ║  when you're not gaming.             ║"
echo "  ║                                      ║"
echo "  ╠══════════════════════════════════════╣"
echo "  ║  To uninstall later, run:            ║"
echo "  ║  ~/.gfn-awdl-watcher/uninstall.sh   ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

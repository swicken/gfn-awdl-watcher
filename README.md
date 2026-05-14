# gfn-awdl-fix

Event-driven fix for GeForce NOW stuttering on macOS caused by Apple Wireless Direct Link (AWDL).

## The problem

macOS uses the `awdl0` network interface for AirDrop, Handoff, and other Apple ecosystem features. It forces your Wi-Fi radio to channel-hop to AWDL's peer-to-peer channel every few seconds, causing **100-300ms latency spikes** — devastating for cloud gaming.

Worse, macOS **aggressively re-enables** `awdl0` even after you disable it. Any Bonjour discovery, AirDrop check, or Finder activity can turn it back on within seconds.

## How this is different

Most existing solutions use **polling** — checking every 1-5 seconds if `awdl0` came back. That leaves a window where your Wi-Fi radio is channel-hopping and your stream is stuttering.

This tool uses macOS's **`SCDynamicStore` API** (via PyObjC) to get **instant callbacks** the moment `awdl0` changes state. It reacts in milliseconds instead of seconds.

| Feature | Bash polling scripts | This tool |
|---|---|---|
| Detection speed | 1-5 seconds | Instant (event-driven) |
| CPU usage | ~0.4-4% (constant fork/exec) | Near zero (idle event loop) |
| GFN auto-launch | Some | Yes |
| Restore on exit | Some | Yes (trap-based) |
| Language | Bash | Python (PyObjC) |

## Requirements

- macOS (tested on Sonoma/Sequoia)
- Python 3.9+
- GeForce NOW installed at `/Applications/GeForceNOW.app`

## Install

```bash
git clone https://github.com/swicken/gfn-awdl-watcher.git
cd gfn-awdl-watcher

# Create venv and install the one dependency
python3 -m venv .venv
.venv/bin/pip install pyobjc-framework-SystemConfiguration

# Run the installer (sets up passwordless sudo for ifconfig + LaunchAgent)
./install.sh
```

The installer does three things:

1. Creates a **scoped sudoers entry** — only allows passwordless `ifconfig awdl0 down/up`, not blanket sudo
2. Installs a **LaunchAgent** that auto-triggers when GeForce NOW opens
3. Logs to `~/Library/Logs/gfn-awdl.log`

## Usage

**Automatic** — just open GeForce NOW normally. The script handles everything and restores `awdl0` when GFN exits.

**Manual** — run directly:

```bash
./gfn-launch.sh
```

## Verify it's working

```bash
# Watch the log in real time
tail -f ~/Library/Logs/gfn-awdl.log

# Check awdl0 status (should say "inactive" while GFN is running)
ifconfig awdl0 | grep status

# Check the watcher process
ps aux | grep awdl-watch
```

## Uninstall

```bash
./uninstall.sh
```

Removes the LaunchAgent, sudoers entry, and restores `awdl0`.

## How it works

1. `gfn-launch.sh` starts the event-driven watcher and launches GFN
2. `awdl-watch.py` subscribes to `SCDynamicStore` network change notifications for the `awdl0` interface
3. When macOS re-enables `awdl0`, the callback fires instantly and disables it
4. A 5-second safety poll runs as a fallback (rarely needed)
5. When GFN exits, `awdl0` is restored so AirDrop/Handoff work normally

## Credits

Inspired by the macOS cloud gaming community, particularly:
- [ComicBit/Geforce-Now-Mac-stutter-free-Launcher](https://github.com/ComicBit/Geforce-Now-Mac-stutter-free-Launcher)
- [meterup/awdl_wifi_scripts](https://github.com/meterup/awdl_wifi_scripts)
- [sjparkinson/geforcenow-awdl0](https://github.com/sjparkinson/geforcenow-awdl0)
- [NVIDIA's official acknowledgment](https://nvidia.custhelp.com/app/answers/detail/a_id/5801/)

## License

MIT

# gfn-awdl-watcher

Fixes GeForce NOW stuttering on macOS over Wi-Fi. One command to install, then it works automatically every time you play.

## What's the problem?

macOS has a feature called **AWDL** (Apple Wireless Direct Link) that powers AirDrop, Handoff, and other Apple ecosystem features. Every few seconds, it forces your Wi-Fi radio to briefly hop to a different channel — causing **100-300ms latency spikes**.

You won't notice this during normal browsing, but it **ruins cloud gaming**. Those spikes show up as micro-stutters, input lag, and frame drops in GeForce NOW.

To make things worse, macOS **constantly re-enables AWDL** even if you turn it off. Every time Finder opens, AirDrop checks for nearby devices, or Bonjour runs a scan — AWDL comes right back.

## What does this do?

This tool **automatically disables AWDL while GeForce NOW is running**, then re-enables it when you're done so AirDrop and Handoff keep working normally.

Unlike other scripts that check every few seconds (letting stutters slip through), this uses macOS's built-in notification system to react **instantly** when AWDL tries to come back.

## Install

### Step 1: Open Terminal

Press **Cmd + Space**, type **Terminal**, and hit Enter.

You'll see a window with a blinking cursor. This is where you'll paste the install command.

### Step 2: Paste this command and hit Enter

```
curl -sL https://raw.githubusercontent.com/swicken/gfn-awdl-watcher/main/quick-install.sh | bash
```

It will ask for your **Mac password** once (you won't see the characters as you type — that's normal). This is needed to give the tool permission to toggle the network interface.

### Step 3: Done

That's it. **Just open GeForce NOW and play.** The fix runs automatically in the background every time you launch GFN. When you quit GFN, AirDrop and Handoff go back to normal.

## How do I know it's working?

Open Terminal and run:

```
tail -f ~/Library/Logs/gfn-awdl.log
```

While GeForce NOW is running, you'll see messages like:

```
2026-05-14 22:01:15 [awdl-watch] Starting event-driven monitor...
2026-05-14 22:01:15 [awdl-watch] awdl0 disabled.
2026-05-14 22:01:15 [awdl-watch] Watching for awdl0 changes (event-driven + 5.0s safety poll)...
2026-05-14 22:03:21 [awdl-watch] awdl0 came up — disabling instantly.
```

That last line means macOS tried to re-enable AWDL and the tool caught it.

Press **Ctrl + C** to stop watching the log.

## Uninstall

Open Terminal and run:

```
~/.gfn-awdl-watcher/uninstall.sh
```

This removes everything and restores your Mac to its original state.

## FAQ

**Does this affect AirDrop?**
Only while GeForce NOW is open. The moment you quit GFN, AirDrop and Handoff work normally again.

**Does this work on Ethernet?**
You don't need this on Ethernet. AWDL only affects Wi-Fi because it shares the same radio.

**Do I need to run anything before each gaming session?**
No. Once installed, it runs automatically every time you open GeForce NOW.

**What macOS versions are supported?**
Tested on Sonoma and Sequoia. Should work on any recent macOS version with Python 3.9+ (included by default).

**Is this safe?**
Yes. It only toggles one network interface (`awdl0`) and only while GFN is running. The source code is ~150 lines and fully readable. The only system change is a scoped permission entry that allows toggling `awdl0` — it does not grant broad admin access.

## How it works (for the curious)

1. A LaunchAgent detects when GeForce NOW opens
2. A Python script subscribes to macOS network change events via the `SCDynamicStore` API
3. The instant macOS re-enables `awdl0`, the callback fires and disables it
4. When GFN exits, `awdl0` is restored

## Credits

Inspired by the macOS cloud gaming community:
- [ComicBit/Geforce-Now-Mac-stutter-free-Launcher](https://github.com/ComicBit/Geforce-Now-Mac-stutter-free-Launcher)
- [meterup/awdl_wifi_scripts](https://github.com/meterup/awdl_wifi_scripts)
- [sjparkinson/geforcenow-awdl0](https://github.com/sjparkinson/geforcenow-awdl0)
- [NVIDIA's official acknowledgment of the issue](https://nvidia.custhelp.com/app/answers/detail/a_id/5801/)

## License

MIT

#!/Users/scott/workspace/scottstuff/gfn/.venv/bin/python3
"""
Event-driven awdl0 monitor using macOS SCDynamicStore.
Reacts instantly to network changes instead of polling.
Falls back to a slow poll as a safety net.
"""

import subprocess
import sys
import signal
import time
from SystemConfiguration import (
    SCDynamicStoreCreate,
    SCDynamicStoreSetNotificationKeys,
    SCDynamicStoreCopyValue,
)
from CoreFoundation import (
    CFRunLoopGetCurrent,
    CFRunLoopAddSource,
    CFRunLoopRunInMode,
    kCFRunLoopDefaultMode,
    CFRunLoopStop,
)
from SystemConfiguration import SCDynamicStoreCreateRunLoopSource


INTERFACE = "awdl0"
FALLBACK_POLL = 5.0


def log(msg):
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    print(f"{ts} [awdl-watch] {msg}", flush=True)


def is_awdl_up():
    try:
        out = subprocess.check_output(
            ["/sbin/ifconfig", INTERFACE], stderr=subprocess.DEVNULL, text=True
        )
        return "status: active" in out
    except subprocess.CalledProcessError:
        return False


def disable_awdl():
    subprocess.run(
        ["sudo", "/sbin/ifconfig", INTERFACE, "down"],
        capture_output=True,
    )


def check_and_disable():
    if is_awdl_up():
        log(f"{INTERFACE} came up — disabling instantly.")
        disable_awdl()
        return True
    return False


def network_change_callback(store, changed_keys, info):
    check_and_disable()


def main():
    log("Starting event-driven monitor...")
    disable_awdl()
    log(f"{INTERFACE} disabled.")

    store = SCDynamicStoreCreate(None, "awdl-watch", network_change_callback, None)
    watch_keys = [
        f"State:/Network/Interface/{INTERFACE}/Link",
        f"State:/Network/Interface/{INTERFACE}/AirDrop",
        "State:/Network/Interface",
    ]
    watch_patterns = [
        "State:/Network/Interface/.*/Link",
        "State:/Network/Service/.*/Interface",
    ]
    SCDynamicStoreSetNotificationKeys(store, watch_keys, watch_patterns)

    source = SCDynamicStoreCreateRunLoopSource(None, store, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode)

    log(f"Watching for {INTERFACE} changes (event-driven + {FALLBACK_POLL}s safety poll)...")

    while True:
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, FALLBACK_POLL, False)
        check_and_disable()


if __name__ == "__main__":
    main()

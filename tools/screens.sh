#!/bin/bash
# Screenshot every DEBUG launch state (GetCracking/App/DebugLaunch.swift) in
# the simulator, plus one fast-clock run from start to hatched. Run after
# tools/check.sh has built the app; tools/check.sh --screens runs both.
#
#   tools/screens.sh [app path]
#
# Screenshots go to $SCREENS_OUT, by default $TMPDIR/getcracking-screens,
# outside the repository. The device is a simulator of its own,
# "Get Cracking 6.9" (iPhone 18 Pro Max),
# made on first use, so no other simulator is touched.
set -uo pipefail
cd "$(dirname "$0")/.."
CHECK_OUT="${CHECK_OUT:-${TMPDIR:-/tmp}/getcracking-check}"
APP="${1:-$CHECK_OUT/build/Debug-iphonesimulator/GetCracking.app}"
OUT="${SCREENS_OUT:-${TMPDIR:-/tmp}/getcracking-screens}"
NAME="Get Cracking 6.9"
BUNDLE=com.belladouglas.getcracking

[ -d "$APP" ] || { echo "no app at $APP (run tools/check.sh first)"; exit 1; }
udid=$(xcrun simctl list devices available | grep -F "$NAME (" | head -1 | grep -oE '[0-9A-F-]{36}')
if [ -z "$udid" ]; then
    # the newest iOS runtime that has this device type
    for rt in $(xcrun simctl list runtimes | grep -oE 'com\.apple\.CoreSimulator\.SimRuntime\.iOS-[0-9-]+' | sort -rV); do
        udid=$(xcrun simctl create "$NAME" com.apple.CoreSimulator.SimDeviceType.iPhone-18-Pro-Max "$rt" 2>/dev/null) && break
    done
    [ -n "$udid" ] || { echo "FAIL could not make the $NAME simulator"; exit 1; }
fi
xcrun simctl boot "$udid" 2>/dev/null
xcrun simctl bootstatus "$udid" -b > /dev/null
xcrun simctl status_bar "$udid" override --time 9:41 --batteryState charged --batteryLevel 100 2>/dev/null
xcrun simctl install "$udid" "$APP" || exit 1
rm -rf "$OUT"; mkdir -p "$OUT"

shot() { xcrun simctl io "$udid" screenshot --type=png "$OUT/$1.png" > /dev/null 2>&1 && echo "$1.png"; }

# state, seconds to wait before the screenshot, extra launch arguments
states=(
    "setup 3" "crack1 3" "crack2 3" "crack3 3" "crack4 3" "crack5 3" "crack6 3" "crack7 3" "crack8 3"
    "timeup 3" "hatch 1.6" "friend 6 -gc-friend fox" "book 3" "world 3" "sound 3" "settings 3"
    "pack-aussie 3" "pack-christmas 3" "gate 3" "paywall 4"
)
for entry in "${states[@]}"; do
    read -r state wait extra <<< "$entry"
    xcrun simctl terminate "$udid" "$BUNDLE" 2>/dev/null
    xcrun simctl launch "$udid" "$BUNDLE" -gc-state "$state" ${extra:-} > /dev/null || { echo "FAIL launch $state"; continue; }
    sleep "$wait"
    shot "$state"
done

# one fast-clock run, 5:00 in 5 s, hatching by itself
xcrun simctl terminate "$udid" "$BUNDLE" 2>/dev/null
xcrun simctl launch "$udid" "$BUNDLE" -gc-state run -gc-fast -gc-friend kookaburra > /dev/null
for s in 0 1 2 3 4 5 6 8 10; do
    sleep $([ "$s" = 0 ] && echo 1.5 || echo 1)
    shot "fast-$(printf %02d "$s")s"
done
xcrun simctl terminate "$udid" "$BUNDLE" 2>/dev/null
echo "screens: $(ls "$OUT" | wc -l | tr -d ' ') files in $OUT"

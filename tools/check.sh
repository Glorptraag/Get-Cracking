#!/bin/bash
# The checks for the iPhone app, run on the Mac: the three check programs in
# Tests/ and a simulator build. Wherever LAUNCH.md says CI, it means this.
#
#   tools/check.sh              checks + build
#   tools/check.sh --no-build   the check programs only
#
# Output (binaries, logs, art contact sheets, the build) goes to
# $CHECK_OUT, by default $TMPDIR/getcracking-check, outside the repository.
# A check program is only recompiled when one of its sources changed.
set -uo pipefail
cd "$(dirname "$0")/.."
OUT="${CHECK_OUT:-${TMPDIR:-/tmp}/getcracking-check}"
mkdir -p "$OUT"
fail=0

# compile <name> <sources…>: swiftc, skipped when the sources are unchanged
compile() {
    local name=$1; shift
    local sum
    sum=$(cat "$@" | shasum | cut -c1-40)
    if [ -x "$OUT/$name" ] && [ "$(cat "$OUT/$name.sha" 2>/dev/null)" = "$sum" ]; then return 0; fi
    rm -f "$OUT/$name.sha"
    swiftc "$@" -o "$OUT/$name" || return 1
    echo "$sum" > "$OUT/$name.sha"
}

# run <label> <name> <args…>: run a compiled check program, keep its log
run() {
    local label=$1 name=$2; shift 2
    echo "== $label"
    "$OUT/$name" "$@" > "$OUT/$label.log" 2>&1
    local r=$?
    grep -c '^PASS' "$OUT/$label.log" | sed 's/^/passed: /'
    grep '^FAIL' "$OUT/$label.log"
    tail -1 "$OUT/$label.log"
    if [ $r -eq 0 ]; then echo "$label: PASS"; else echo "$label: FAIL"; fail=1; fi
}

if compile gatecheck GetCracking/Monetization/Packs.swift GetCracking/Monetization/FeatureGate.swift \
    GetCracking/Monetization/ProductID.swift GetCracking/Model/TimeDial.swift Tests/GateChecks/*.swift; then
    run gate gatecheck
else echo "gate: FAIL (compile)"; fail=1; fi

if compile karaokecheck GetCracking/Audio/KaraokeData.swift GetCracking/Audio/KaraokeIndex.swift \
    GetCracking/Monetization/Packs.swift Tests/KaraokeChecks/*.swift; then
    run karaoke karaokecheck
else echo "karaoke: FAIL (compile)"; fail=1; fi

if compile artcheck GetCracking/Core/VNode.swift GetCracking/Core/SVGPath.swift GetCracking/Core/Motion.swift GetCracking/Core/Util.swift \
    GetCracking/Art/Animals.swift GetCracking/Art/Loops.swift GetCracking/Art/Props.swift GetCracking/Art/Scenes.swift \
    GetCracking/Art/EggArt.swift GetCracking/Art/Icons.swift \
    GetCracking/Art/Packs/*.swift GetCracking/Monetization/Packs.swift Tests/ArtChecks/*.swift; then
    run art artcheck "$OUT/art-png"
else echo "art: FAIL (compile)"; fail=1; fi

if [ "${1:-}" != "--no-build" ]; then
    echo "== simulator build"
    xcodebuild -project GetCracking.xcodeproj -target GetCracking -sdk iphonesimulator -configuration Debug \
        ONLY_ACTIVE_ARCH=YES ARCHS=arm64 CODE_SIGNING_ALLOWED=NO SYMROOT="$OUT/build" OBJROOT="$OUT/obj" \
        build > "$OUT/build.log" 2>&1
    if grep -q "BUILD SUCCEEDED" "$OUT/build.log"; then
        echo "app: $OUT/build/Debug-iphonesimulator/GetCracking.app"
        echo "build: PASS"
    else
        grep -E "error:" "$OUT/build.log" | sort -u | head -30
        echo "build: FAIL"; fail=1
    fi
fi

if [ $fail -eq 0 ]; then echo "ALL CHECKS PASSED"; else echo "CHECKS FAILED"; fi
exit $fail

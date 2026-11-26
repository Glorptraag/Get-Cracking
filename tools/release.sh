#!/bin/bash
# Archive the iPhone app and send it to TestFlight. Run on the Mac.
#
#   tools/release.sh archive   archive only; prints the build number
#   tools/release.sh upload    archive, export with the App Store Connect API key, upload to TestFlight
#
# The build number (CFBundleVersion) is the commit count of HEAD, set at
# archive time, so every commit archives with a new, higher number and
# App Store Connect never refuses an upload as a duplicate. The version
# (CFBundleShortVersionString) stays MARKETING_VERSION in the project.
#
# Upload needs the API key (App Manager role) in the environment:
#   ASC_KEY_ID, ASC_ISSUER_ID, and ASC_KEY_P8 (the .p8 file's contents)
#   or ASC_KEY_PATH (the path to the .p8 file).
#
# Output goes to $RELEASE_OUT, by default $TMPDIR/getcracking-release.
set -euo pipefail
cd "$(dirname "$0")/.."
mode="${1:-archive}"
OUT="${RELEASE_OUT:-${TMPDIR:-/tmp}/getcracking-release}"
mkdir -p "$OUT"

if [ "$mode" = "upload" ] && [ -n "$(git status --porcelain)" ]; then
    echo "The working tree has changes; commit them first so the build number names a real commit." >&2
    exit 1
fi

build=$(git rev-list --count HEAD)
sha=$(git rev-parse --short HEAD)
archive="$OUT/GetCracking-$build.xcarchive"

auth=()
if [ "$mode" = "upload" ]; then
    : "${ASC_KEY_ID:?set ASC_KEY_ID}" "${ASC_ISSUER_ID:?set ASC_ISSUER_ID}"
    key="${ASC_KEY_PATH:-}"
    if [ -z "$key" ]; then
        : "${ASC_KEY_P8:?set ASC_KEY_P8 or ASC_KEY_PATH}"
        key="$OUT/AuthKey_$ASC_KEY_ID.p8"
        (umask 077; printf '%s\n' "$ASC_KEY_P8" > "$key")
        trap 'rm -f "$key"' EXIT
    fi
    auth=(-allowProvisioningUpdates -authenticationKeyPath "$key"
          -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID")
fi

echo "== archive build $build ($sha)"
rm -rf "$archive"
sign=()
[ "$mode" = "archive" ] && sign=(CODE_SIGNING_ALLOWED=NO)
xcodebuild -project GetCracking.xcodeproj -scheme GetCracking -configuration Release \
    -destination 'generic/platform=iOS' -archivePath "$archive" \
    CURRENT_PROJECT_VERSION="$build" ${sign[@]+"${sign[@]}"} ${auth[@]+"${auth[@]}"} \
    archive > "$OUT/archive-$build.log" 2>&1 || { grep -E "error:" "$OUT/archive-$build.log" | sort -u | head -30; exit 1; }
plist="$archive/Products/Applications/GetCracking.app/Info.plist"
echo "archive: $archive"
echo "CFBundleShortVersionString: $(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$plist")"
echo "CFBundleVersion: $(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$plist")"

[ "$mode" = "upload" ] || exit 0

cat > "$OUT/ExportOptions.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key><string>app-store-connect</string>
    <key>destination</key><string>upload</string>
    <key>teamID</key><string>B68AX5ZHDT</string>
    <key>signingStyle</key><string>automatic</string>
    <key>manageAppVersionAndBuildNumber</key><false/>
    <key>uploadSymbols</key><true/>
</dict>
</plist>
PLIST

echo "== export and upload build $build"
xcodebuild -exportArchive -archivePath "$archive" -exportPath "$OUT/export-$build" \
    -exportOptionsPlist "$OUT/ExportOptions.plist" "${auth[@]}" > "$OUT/upload-$build.log" 2>&1 \
    || { grep -E "error|Error" "$OUT/upload-$build.log" | sort -u | head -30; exit 1; }
grep -E "Upload succeeded|EXPORT SUCCEEDED|Uploaded" "$OUT/upload-$build.log" | tail -3
echo "uploaded: Get Cracking 1.0 ($build) from $sha"

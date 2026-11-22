#!/usr/bin/env bash
# Make a stand-alone Advent Eggs repo from Get-Cracking (both branches) and build it.
#
# Run on a Mac with Xcode 16+, from inside a clone of Get-Cracking:
#   bash AdventEggs/tools/setup-and-build.sh            # build only
#   NEW_REPO=AdventEggs bash AdventEggs/tools/setup-and-build.sh   # also create a private GitHub repo (needs `gh auth login`)
#
# What it does:
#   1. makes sure both branches are local: `main` (Get Cracking) and `advent` (Advent Eggs)
#   2. if NEW_REPO is set, creates that private GitHub repo and pushes both branches to it
#   3. builds Advent Eggs for the iOS Simulator (no signing needed) and says whether it built
set -euo pipefail

ADVENT_BRANCH="claude/elegant-lamport-u6vacd"
cd "$(git rev-parse --show-toplevel)"

echo "== 1. branches"
git fetch origin main "$ADVENT_BRANCH"
git show-ref --verify --quiet refs/heads/main || git branch --track main origin/main
git show-ref --verify --quiet refs/heads/advent || git branch --track advent "origin/$ADVENT_BRANCH"
git checkout -q advent
git branch -vv | sed 's/^/   /'

if [ -n "${NEW_REPO:-}" ]; then
  echo "== 2. new GitHub repo: $NEW_REPO"
  command -v gh >/dev/null || { echo "gh (GitHub CLI) is not installed: brew install gh && gh auth login"; exit 1; }
  if ! git remote | grep -qx upstream; then git remote rename origin upstream; fi
  if ! git remote | grep -qx origin; then gh repo create "$NEW_REPO" --private --source . --remote origin; fi
  git push -u origin main advent
else
  echo "== 2. (skipped: set NEW_REPO=Name to create a new GitHub repo)"
fi

echo "== 3. build"
command -v xcodebuild >/dev/null || { echo "xcodebuild not found: install Xcode 16+ and run: sudo xcode-select -s /Applications/Xcode.app"; exit 1; }
LOG="$(mktemp -t advent-build).log"
if xcodebuild -project AdventEggs/AdventEggs.xcodeproj -target AdventEggs -sdk iphonesimulator \
     -configuration Debug CODE_SIGNING_ALLOWED=NO build >"$LOG" 2>&1; then
  echo "BUILD SUCCEEDED. Open AdventEggs/AdventEggs.xcodeproj, pick a simulator and press Run."
else
  echo "BUILD FAILED. The errors:"
  grep -E "error:" "$LOG" | sort -u | head -40
  echo "(full log: $LOG) Paste the errors above to Claude to fix."
  exit 1
fi

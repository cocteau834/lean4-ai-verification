#!/usr/bin/env bash
# Runs once when the Codespace is created: installs Lean and downloads prebuilt Mathlib (about 11 GB in all).
#
# Codespaces keeps the home folder on a small disk, so Lean (~3 GB) and Mathlib's download cache are stored
# in the workspace folder instead (in .lean-home/, which git ignores) and linked from their usual places.
set -euo pipefail

WS="$(pwd)"
BIG="$WS/.lean-home"
show_space() { echo "── disk space ($1) ──"; df -h "$HOME" "$WS" 2>/dev/null | awk 'NR==1 || !seen[$0]++'; echo; }
show_space "before setup"

mkdir -p "$BIG/elan" "$BIG/mathlib-cache" "$HOME/.cache"
for pair in "$HOME/.elan:$BIG/elan" "$HOME/.cache/mathlib:$BIG/mathlib-cache"; do
  link="${pair%%:*}"; target="${pair#*:}"
  if [ -e "$link" ] && [ ! -L "$link" ]; then rm -rf "$link"; fi   # leftovers from an earlier failed setup
  ln -sfn "$target" "$link"
done

if [ ! -x "$HOME/.elan/bin/elan" ]; then
  curl -sSfL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh \
    | sh -s -- -y --default-toolchain none
fi
export PATH="$HOME/.elan/bin:$PATH"

if ! lake exe cache get; then
  show_space "after the failed download"
  echo "❌ Downloading Mathlib failed. If the messages above say 'No space left on device', delete this"
  echo "   codespace (github.com/codespaces) and create a new one; otherwise rerun: bash .devcontainer/setup.sh"
  exit 1
fi
rm -f "$BIG"/mathlib-cache/*.ltar   # the archives are unpacked into .lake now; this frees about 0.5 GB

pip install --user --quiet -r tools/miniprover/requirements.txt || true
show_space "after setup"
echo "✅ Lean + Mathlib are ready. Open START_HERE.md for the next step."

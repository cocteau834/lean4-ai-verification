#!/usr/bin/env bash
# Runs once when the Codespace is created: installs Lean and downloads prebuilt Mathlib (about 11 GB in all).
#
# This only fits on GitHub's 8-core / 64 GB machine: on the standard 32 GB machine GitHub's own files
# leave about 9.5 GB free, which is not enough. devcontainer.json asks for the bigger machine.
set -euo pipefail

WS="$(pwd)"
show_space() { echo "── disk space ($1) ──"; df -h "$HOME" "$WS" 2>/dev/null | awk 'NR==1 || !seen[$0]++'; echo; }
show_space "before setup"

if [ ! -x "$HOME/.elan/bin/elan" ]; then
  curl -sSfL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh \
    | sh -s -- -y --default-toolchain none
fi
export PATH="$HOME/.elan/bin:$PATH"

if ! lake exe cache get; then
  show_space "after the failed download"
  echo "❌ Downloading Mathlib failed. If the messages above say 'No space left on device', this codespace"
  echo "   is too small: delete it (github.com/codespaces) and create one on the 8-core / 64 GB machine type."
  echo "   Otherwise rerun: bash .devcontainer/setup.sh"
  exit 1
fi
rm -f "$HOME"/.cache/mathlib/*.ltar   # the archives are unpacked into .lake now; this frees about 0.5 GB

pip install --user --quiet -r tools/miniprover/requirements.txt || true
show_space "after setup"
echo "✅ Lean + Mathlib are ready. Open START_HERE.md for the next step."

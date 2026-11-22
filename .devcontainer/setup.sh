#!/usr/bin/env bash
# Runs once when the Codespace is created: installs Lean and downloads prebuilt Mathlib.
set -euo pipefail
if [ ! -x "$HOME/.elan/bin/elan" ]; then
  curl -sSfL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh \
    | sh -s -- -y --default-toolchain none
fi
export PATH="$HOME/.elan/bin:$PATH"
lake exe cache get
pip install --user --quiet -r tools/miniprover/requirements.txt || true
echo ""
echo "✅ Lean + Mathlib are ready. Open START_HERE.md for the next step."

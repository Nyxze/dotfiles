#!/usr/bin/env bash
# Non-GUI validation; safe to run anywhere (no compositor calls).
set -euo pipefail
cd "$(dirname "$0")/../.."
python3 -m py_compile tools/visual-harness/vh.py
python3 -m unittest discover -s tools/visual-harness/tests -v

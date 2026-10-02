#!/usr/bin/env bash
# Kept for muscle memory; deploy is the canonical interface.
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
exec "$repo_root/deploy" "$@"

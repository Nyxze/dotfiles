#!/usr/bin/env bash
set -euo pipefail

skill_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
output_path="${1:-$skill_dir/references/component-gallery.pdf}"

command -v rsvg-convert >/dev/null || { printf 'rsvg-convert is required\n' >&2; exit 1; }
command -v uv >/dev/null || { printf 'uv is required\n' >&2; exit 1; }

rsvg-convert -w 1200 -h 675 \
  -o "$skill_dir/assets/gallery/sample-image.png" \
  "$skill_dir/assets/gallery/sample-image.svg"

uv run --quiet --script "$skill_dir/scripts/render_pdf.py" \
  "$skill_dir/references/component-gallery.md" "$output_path"

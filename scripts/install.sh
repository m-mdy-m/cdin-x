#!/bin/sh
# Install the CDIN-X runtime and built-in extension bundle into a CDIN tree.
# Usage: ./scripts/install.sh /path/to/cdin [--symlink]
#   --symlink: use symlinks instead of copies (for development)
set -eu

CDIN_DIR="${1:-}"
SYMLINK=0
shift 2>/dev/null || true
if [ "${1:-}" = "--symlink" ]; then
  SYMLINK=1
fi

if [ -z "$CDIN_DIR" ]; then
  echo "Usage: $0 /path/to/cdin [--symlink]" >&2
  exit 1
fi

if [ ! -d "$CDIN_DIR" ]; then
  echo "✗ cdin directory not found: $CDIN_DIR" >&2
  exit 1
fi

mkdir -p "$CDIN_DIR/data/core/x" "$CDIN_DIR/data/X/core" "$CDIN_DIR/data/fonts" "$CDIN_DIR/data/X/themes"

if [ "$SYMLINK" = "1" ]; then
  # Development mode: symlinks so cdin-x changes are immediately reflected
  rm -f "$CDIN_DIR/data/core/x"
  ln -sf "$(pwd)/core" "$CDIN_DIR/data/core/x"
  rm -f "$CDIN_DIR/data/X"
  ln -sf "$(pwd)/X" "$CDIN_DIR/data/X"
  rm -f "$CDIN_DIR/data/fonts"
  ln -sf "$(pwd)/fonts" "$CDIN_DIR/data/fonts"
  echo "CDIN-X installed (symlink mode): $CDIN_DIR"
  echo "  data/core/x -> $(pwd)/core"
  echo "  data/X       -> $(pwd)/X"
  echo "  data/fonts   -> $(pwd)/fonts"
else
  # Production mode: copy files
  mkdir -p "$CDIN_DIR/data/core/x"
  cp -R core/. "$CDIN_DIR/data/core/x/"

  for dir in X/core/*/; do
    name="$(basename "$dir")"
    manifest="$dir/manifest.lua"
    if [ -f "$manifest" ] && grep -q "essential[[:space:]]*=[[:space:]]*true" "$manifest"; then
      rm -rf "$CDIN_DIR/data/X/core/$name"
      mkdir -p "$CDIN_DIR/data/X/core/$name"
      cp -R "$dir." "$CDIN_DIR/data/X/core/$name/"
    fi
  done

  for dir in X/themes/*/; do
    name="$(basename "$dir")"
    theme_file="$dir/theme.lua"
    if [ -f "$theme_file" ] && grep -q "essential[[:space:]]*=[[:space:]]*true" "$theme_file"; then
      rm -rf "$CDIN_DIR/data/X/themes/$name"
      mkdir -p "$CDIN_DIR/data/X/themes/$name"
      cp "$theme_file" "$CDIN_DIR/data/X/themes/$name/theme.lua"
    fi
  done

  rm -rf "$CDIN_DIR/data/fonts"
  mkdir -p "$CDIN_DIR/data/fonts"
  if [ -d fonts ] && [ -n "$(ls -A fonts 2>/dev/null)" ]; then
    cp -R fonts/. "$CDIN_DIR/data/fonts/"
  else
    echo "⚠ cdin-x/fonts/ is missing or empty — skipping font install." >&2
    echo "  cdin will fail to start until data/fonts/ contains:" >&2
    echo "  font.ttf, icons.ttf, monospace.ttf, fallback.ttf, emoji.ttf" >&2
  fi

  echo "CDIN-X runtime installed into: $CDIN_DIR"
  echo "Optional extensions remain in the cdin-x registry and are installed per-user."
fi

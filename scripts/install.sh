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
  rm -rf "$CDIN_DIR/data/core/x"
  ln -sf "$(pwd)/core" "$CDIN_DIR/data/core/x"
  rm -rf "$CDIN_DIR/data/X"
  ln -sf "$(pwd)/X" "$CDIN_DIR/data/X"

  if [ -d fonts ] && [ -n "$(ls -A fonts 2>/dev/null)" ]; then
    rm -rf "$CDIN_DIR/data/fonts"
    ln -sf "$(pwd)/fonts" "$CDIN_DIR/data/fonts"
    echo "  data/fonts   -> $(pwd)/fonts"
  elif [ ! -d "$CDIN_DIR/data/fonts" ]; then
    echo "⚠ no fonts found: cdin-x/fonts/ is missing and $CDIN_DIR/data/fonts/ does not exist." >&2
  else
    echo "  data/fonts   left alone (cdin-x has no fonts/ to link)"
  fi

  echo "CDIN-X installed (symlink mode): $CDIN_DIR"
  echo "  data/core/x -> $(pwd)/core"
  echo "  data/X       -> $(pwd)/X"
else
  # Production mode: copy files
  mkdir -p "$CDIN_DIR/data/core/x"
  cp -R core/. "$CDIN_DIR/data/core/x/"

  # Is this file an essential manifest?
  is_essential() {
    grep -q "essential[[:space:]]*=[[:space:]]*true" "$1" 2>/dev/null
  }

  for dir in X/core/*/; do
    [ -d "$dir" ] || continue
    name="$(basename "$dir")"
    essential=0
    if [ -f "$dir/manifest.lua" ] && is_essential "$dir/manifest.lua"; then
      essential=1
    elif [ -f "$dir/init.lua" ] && is_essential "$dir/init.lua"; then
      essential=1
    fi
    if [ "$essential" = "1" ]; then
      rm -rf "$CDIN_DIR/data/X/core/$name"
      mkdir -p "$CDIN_DIR/data/X/core/$name"
      cp -R "$dir." "$CDIN_DIR/data/X/core/$name/"
    fi
  done

  # Single-file core plugins (X/core/<name>.lua) can be essential too.
  for file in X/core/*.lua; do
    [ -f "$file" ] || continue
    name="$(basename "$file" .lua)"
    if is_essential "$file"; then
      mkdir -p "$CDIN_DIR/data/X/core"
      cp "$file" "$CDIN_DIR/data/X/core/$name.lua"
    fi
  done

  for dir in X/themes/*/; do
    [ -d "$dir" ] || continue
    name="$(basename "$dir")"
    theme_file="$dir/theme.lua"
    if [ -f "$theme_file" ] && is_essential "$theme_file"; then
      rm -rf "$CDIN_DIR/data/X/themes/$name"
      mkdir -p "$CDIN_DIR/data/X/themes/$name"
      cp "$theme_file" "$CDIN_DIR/data/X/themes/$name/theme.lua"
    fi
  done

  if [ -d fonts ] && [ -n "$(ls -A fonts 2>/dev/null)" ]; then
    rm -rf "$CDIN_DIR/data/fonts"
    mkdir -p "$CDIN_DIR/data/fonts"
    cp -R fonts/. "$CDIN_DIR/data/fonts/"
  elif [ ! -d "$CDIN_DIR/data/fonts" ]; then
    echo "⚠ no fonts found: cdin-x/fonts/ is missing and $CDIN_DIR/data/fonts/ does not exist." >&2
    echo "  cdin will fail to start until data/fonts/ contains:" >&2
    echo "  font.ttf, icons.ttf, monospace.ttf, fallback.ttf, emoji.ttf"
  fi

  echo "CDIN-X runtime installed into: $CDIN_DIR"
  echo "Optional extensions remain in the cdin-x registry and are installed per-user."
fi

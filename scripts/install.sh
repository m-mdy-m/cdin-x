#!/bin/sh
set -eu
CDIN_DIR="${1:-}"
SYMLINK=0;shift 2>/dev/null || true;[ "${1:-}" = "--symlink" ] && SYMLINK=1
[ -z "$CDIN_DIR" ] && { echo "Usage: $0 /path/to/cdin [--symlink]" >&2; exit 1; }
[ ! -d "$CDIN_DIR" ] && { echo "cdin dir not found" >&2; exit 1; }
if [ "$SYMLINK" = "1" ]; then
  rm -rf "$CDIN_DIR/data/core/x";ln -sf "$(pwd)/core" "$CDIN_DIR/data/core/x"
  rm -rf "$CDIN_DIR/data/X";ln -sf "$(pwd)/X" "$CDIN_DIR/data/X"
  rm -rf "$CDIN_DIR/data/fonts";ln -sf "$(pwd)/fonts" "$CDIN_DIR/data/fonts"
  echo "CDIN-X installed (symlink): $CDIN_DIR"
else
  mkdir -p "$CDIN_DIR/data/core/x";cp -R core/. "$CDIN_DIR/data/core/x/"
  for n in core autocomplete autoreload autoupdate projectsearch session trimwhitespace vim treeview tab window; do
    [ -d "X/core/$n" ] && { rm -rf "$CDIN_DIR/data/X/core/$n";mkdir -p "$CDIN_DIR/data/X/core/$n";cp -R "X/core/$n/." "$CDIN_DIR/data/X/core/$n/" 2>/dev/null || true; }
  done
  [ -f "X/themes/default/theme.lua" ] && { rm -rf "$CDIN_DIR/data/X/themes/default";mkdir -p "$CDIN_DIR/data/X/themes/default";cp "X/themes/default/theme.lua" "$CDIN_DIR/data/X/themes/default/theme.lua"; }
  rm -rf "$CDIN_DIR/data/fonts";mkdir -p "$CDIN_DIR/data/fonts";cp -R fonts/. "$CDIN_DIR/data/fonts/"
  echo "CDIN-X installed: $CDIN_DIR"
fi

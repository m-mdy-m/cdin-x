#!/usr/bin/env python3
"""Produce the mandatory bundle a cdin build needs.

A cdin checkout contains only its runtime. The mandatory set — the vim
plugin, the default theme and the fonts — lives here, in cdin-x. A cdin
build runs this once, at build time, and copies the result into its own
output directory. Nothing is fetched: this reads a checkout on disk and
writes files.

    python3 scripts/bundle.py --out <DEST_DATA_DIR>

and the destination ends up looking exactly like this:

    <DEST>/X/core/<n>/**          verbatim copy of each essential directory
                                  plugin, X.* namespace preserved
    <DEST>/X/core/<n>.lua         verbatim copy of each essential
                                  single-file plugin
    <DEST>/plugins/<n>.lua        one-line shim: return require("X.core.<n>")
    <DEST>/<support>/**           verbatim copy of every `bundle_with` path
                                  an essential plugin declares
    <DEST>/themes/<t>/theme.lua   the essential theme(s)
    <DEST>/fonts/**               copy of this repository's fonts/
    <DEST>/BUNDLE.lua             return { plugins = {...}, themes = {...} }

Why the shims: the host's plugin loader looks for plugins in one bundled
directory, and it dofile()s the entry point it finds there. vim's real
entry point is X/core/vim/init.lua, and loading it by that path would run
the file a second time under a different module identity. A one-line shim
that `require`s the real module gives the host the name it wants without
giving vim a second init.

`bundle_with` is the same problem one level up. An essential plugin may have
code that does not live under X/: the manager ships as X/core/manager/init.lua
and its modules are in cdinx/. Declaring `bundle_with = { "cdinx" }` on the
plugin's manifest copies those paths into the destination with their layout
intact, so `require "cdinx"` resolves from <DEST>/cdinx/ exactly as it does
from a checkout. The bundler does not guess at this: an undeclared dependency
is a build whose editor starts and then does nothing, which is not a failure
anyone should have to debug at runtime.

Essential is a marker on a plugin, not a file listing: `essential = true` in
its manifest means "a cdin build without this is not a working editor", which
is the bundler's entire selection rule. The one essential theme is default.
Adding a second essential thing is a deliberate act, not an accident of
layout.

Stdlib only, Python 3.8+, no network, no imports from cdin.
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import sys
from pathlib import Path

# `essential = true` at the start of a line, ignoring indentation. Comments
# are stripped before this runs, so a plugin that merely mentions
# "essential = true" in a header comment is not mistaken for one.
ESSENTIAL_RE = re.compile(r"^\s*essential\s*=\s*true\b", re.MULTILINE)

# `bundle_with = { "cdinx", ... }` — support paths an essential plugin needs
# beside it in a build. Read as text, not executed, for the same reason
# `essential` is: a build step that runs plugin code to learn what to copy is
# a build step with the plugin's side effects.
BUNDLE_WITH_RE = re.compile(r"bundle_with\s*=\s*\{([^}]*)\}", re.MULTILINE)
QUOTED_RE = re.compile(r'"([^"]*)"|\'([^\']*)\'')

# Lua comments: --[[ ... ]] blocks, --[==[ ... ]==] blocks, and -- to EOL.
# A string containing "--" would be mangled by the second pass; none of the
# manifests this runs against put one before their essential line, and the
# cost of a false negative is a loud error rather than a silent wrong bundle.
_BLOCK_COMMENT_RE = re.compile(r"--\[(=*)\[.*?\]\1\]", re.DOTALL)
_LINE_COMMENT_RE = re.compile(r"--[^\n]*")


def is_link(path: Path) -> bool:
    """True for a symlink, a junction, or any other reparse point.

    os.path.islink is false for a Windows junction, and a junction is
    exactly as dangerous here: it redirects writes to another tree. Any
    reparse point is treated as a link — unlinked, never traversed. Erring
    that way is safe because only entries this script owns are ever tested.
    """
    if os.path.islink(path):
        return True
    if sys.platform == "win32":
        try:
            st = os.lstat(path)
        except OSError:
            return False
        return bool(getattr(st, "st_file_attributes", 0) & 0x400)
    return False


def _force_utf8_stdio() -> None:
    """Let the status lines print on a Windows console.

    Python defaults stdout to the ANSI code page, which is cp1252 on most
    Western installs and cannot encode the tick below. A build step that
    dies on its own success message is worse than one that prints a box.
    """
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(encoding="utf-8", errors="replace")
        except (AttributeError, ValueError):
            pass


def die(message: str) -> "NoReturn":  # type: ignore[valid-type]
    print("✗ " + message, file=sys.stderr)
    sys.exit(1)


def strip_lua_comments(src: str) -> str:
    return _LINE_COMMENT_RE.sub("", _BLOCK_COMMENT_RE.sub("", src))


def is_essential(path: Path) -> bool:
    """True when the Lua file at `path` declares essential = true.

    The file is read as text, not executed. A manifest can call functions,
    read the clock, or raise; none of that is acceptable in a build step
    that only needs to know which files to copy.
    """
    try:
        src = path.read_text(encoding="utf-8", errors="replace")
    except OSError as exc:
        die("cannot read {}: {}".format(path, exc))
    return ESSENTIAL_RE.search(strip_lua_comments(src)) is not None


def manifest_of(plugin_dir: Path):
    """The file that carries a directory plugin's manifest, or None."""
    for name in ("manifest.lua", "init.lua"):
        candidate = plugin_dir / name
        if candidate.is_file():
            return candidate
    return None


def bundle_with_of(manifest):
    """Support paths a plugin declares with `bundle_with = { ... }`.

    Repository-relative, normalized to forward slashes so the destination
    layout does not depend on which platform ran the bundler. An empty list
    is the normal answer: only a plugin whose code lives outside X/ has one.

    Read as text, for the same reason `essential` is read as text: a build
    step that executes a plugin to learn what to copy has run the plugin.
    """
    if manifest is None:
        return []
    try:
        src = manifest.read_text(encoding="utf-8", errors="replace")
    except OSError as exc:
        die("cannot read {}: {}".format(manifest, exc))

    match = BUNDLE_WITH_RE.search(strip_lua_comments(src))
    if not match:
        return []

    paths = []
    for dquoted, squoted in QUOTED_RE.findall(match.group(1)):
        name = (dquoted or squoted).strip().replace("\\", "/")
        # A path that escapes the repository is never a support path, whatever
        # the manifest says. Refusing loudly beats copying something out of
        # the tree on the strength of a string in a file nobody re-reads.
        if not name or name.startswith("/") or ".." in name.split("/"):
            die("{}: bundle_with has an unusable path: {!r}".format(manifest, name))
        if name not in paths:
            paths.append(name)
    return paths


def copy_file(src: Path, dst: Path) -> None:
    """A real copy, byte for byte, with no timestamps.

    shutil.copy2 would preserve mtime, which makes the bundle depend on when
    the source was checked out and defeats any comparison between two runs.
    """
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(src, dst)


def copy_tree(src: Path, dst: Path) -> None:
    """Copy a directory tree verbatim: no symlinks, no metadata."""
    for item in sorted(src.iterdir(), key=lambda p: p.name):
        if item.is_dir() and not item.is_symlink():
            copy_tree(item, dst / item.name)
        elif item.is_file():
            copy_file(item, dst / item.name)
        # Anything else (a socket, a dangling symlink) is not bundle material.


def essential_plugins(x_root: Path):
    """(directory plugins, single-file plugins) marked essential.

    Directory plugins are X/core/<n>/, single-file ones are X/core/<n>.lua.
    A single .lua file is a candidate on its own evidence; a directory needs
    a manifest, so a stray README-only directory is not a plugin.
    """
    core_root = x_root / "core"
    if not core_root.is_dir():
        return [], []

    dirs, singles = [], []
    for item in sorted(core_root.iterdir(), key=lambda p: p.name):
        if item.is_dir() and not item.is_symlink():
            manifest = manifest_of(item)
            if manifest is not None and is_essential(manifest):
                dirs.append(item)
        elif item.is_file() and item.suffix == ".lua":
            if is_essential(item):
                singles.append(item)
    return dirs, singles


def essential_themes(x_root: Path):
    """Theme directories marked essential, from X/themes/<name>/theme.lua."""
    themes_root = x_root / "themes"
    if not themes_root.is_dir():
        return []

    found = []
    for item in sorted(themes_root.iterdir(), key=lambda p: p.name):
        if not item.is_dir() or item.is_symlink():
            continue
        theme = item / "theme.lua"
        if theme.is_file() and is_essential(theme):
            found.append(item)
    return found


def write_shim(dst: Path, name: str) -> None:
    """The one-line entry point the host's loader dofile()s."""
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_text('return require("X.core.{}")\n'.format(name), encoding="utf-8",
                   newline="\n")


def write_index(out: Path, plugins, themes) -> None:
    def lua_list(names):
        return "{ " + ", ".join('"' + n + '"' for n in sorted(names)) + " }"

    body = (
        "-- Generated by cdin-x's scripts/bundle.py. Do not edit.\n"
        "--\n"
        "-- What this build bundles from cdin-x. Written so a build can be\n"
        "-- checked without diffing the whole tree, and so an installed copy\n"
        "-- can say which cdin-x revision it came from.\n"
        "return {\n"
        "  plugins = " + lua_list(plugins) + ",\n"
        "  themes = " + lua_list(themes) + ",\n"
        "}\n"
    )
    (out / "BUNDLE.lua").write_text(body, encoding="utf-8", newline="\n")


def reset(out: Path, support=()) -> None:
    """Clear only what this script owns, then rebuild it.

    Idempotent by construction: a second run over a first run's output
    produces byte-identical files. The other entries in the destination are
    left strictly alone — in particular `core`, which is the host's own
    runtime and is not ours to touch.

    `support` is the top level of every `bundle_with` path. Those are ours
    too, and they are cleared here for the same reason X/ is: a directory
    this script copies into and does not clear is how a file deleted from a
    plugin survives in every build after it.
    """
    owned = ["X", "plugins", "themes", "fonts"]
    for path in support:
        top = path.replace("\\", "/").split("/")[0]
        if top and top not in owned:
            owned.append(top)

    for name in owned:
        target = out / name
        if is_link(target):
            # A link here would make rmtree delete through to whatever it
            # points at. Unlink it; never traverse.
            os.unlink(target)
        elif target.is_dir():
            shutil.rmtree(target)
        elif target.exists():
            target.unlink()

    index = out / "BUNDLE.lua"
    if is_link(index):
        os.unlink(index)
    elif index.exists():
        index.unlink()


def main() -> int:
    default_root = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser(
        description="Bundle the mandatory CDIN-X set for a cdin build.")
    parser.add_argument("--out", required=True, type=Path,
                        help="destination data/ directory")
    parser.add_argument("--cdinx-root", type=Path, default=default_root,
                        help="cdin-x checkout (default: this repository)")
    args = parser.parse_args()

    root = args.cdinx_root
    out = args.out

    # The destination has to be a real directory. A symlink or junction left
    # by an older build layout points at some other tree, and writing the
    # bundle through it would put build output inside that tree.
    if is_link(out):
        die("--out is a symlink or junction ({}); refusing to write through "
            "it. Point it at a real directory.".format(out))

    x_root = root / "X"
    if not x_root.is_dir():
        die("no X/ under {} — is --cdinx-root pointing at a cdin-x checkout?"
            .format(root))

    dirs, singles = essential_plugins(x_root)
    plugin_names = [d.name for d in dirs] + [f.stem for f in singles]

    if not plugin_names:
        die("no essential plugin found under X/core/ — a cdin build without "
            "one is not a working editor. Mark the plugin that is "
            "`essential = true` in its manifest.")

    # Support files an essential plugin declares with `bundle_with`. Collected
    # before anything is written so a bad path stops the build rather than
    # half-assembling it.
    support = []
    for plugin in dirs + singles:
        for rel in bundle_with_of(manifest_of(plugin) if plugin.is_dir() else plugin):
            src = root / rel
            if not src.exists():
                die("{} declares bundle_with = {{ {} }} but {} is not there"
                    .format(plugin.name, rel, src))
            if rel not in support:
                support.append(rel)

    themes = essential_themes(x_root)
    theme_names = [t.name for t in themes]
    if len(theme_names) != 1:
        die("expected exactly one essential theme under X/themes/, found {}{}."
            .format(len(theme_names),
                    ": " + ", ".join(theme_names) if theme_names else ""))

    # The fonts are not optional and are not substituted. A cdin build with
    # no fonts does not start, and a build that silently shipped without
    # them would be discovered by the user, at startup, with no way to tell
    # why.
    fonts_src = root / "fonts"
    if not fonts_src.is_dir() or not any(fonts_src.iterdir()):
        die("no fonts in {}. The bundled fonts are the ones this repository "
            "ships; a cdin build cannot start without them, and nothing here "
            "will substitute a different set.".format(fonts_src))

    out.mkdir(parents=True, exist_ok=True)
    reset(out, support)

    # X/** — verbatim, namespace preserved, so that a require of a vim
    # submodule still resolves the same way it does here.
    for plugin in dirs:
        copy_tree(plugin, out / "X" / "core" / plugin.name)
    for plugin in singles:
        copy_file(plugin, out / "X" / "core" / plugin.name)

    # plugins/** — the shims the host's loader looks for.
    for name in plugin_names:
        write_shim(out / "plugins" / (name + ".lua"), name)

    # themes/** — the host's theme layout.
    for theme in themes:
        copy_file(theme / "theme.lua", out / "themes" / theme.name / "theme.lua")

    # <support>/** — verbatim, at the top level, so a plugin's own module
    # namespace is the same in a build as in a checkout.
    for rel in support:
        src = root / rel
        dst = out / rel
        if src.is_dir() and not src.is_symlink():
            copy_tree(src, dst)
        else:
            copy_file(src, dst)

    # fonts/** — verbatim.
    copy_tree(fonts_src, out / "fonts")

    write_index(out, plugin_names, theme_names)

    print("✓ bundled {} plugin(s) [{}], theme(s) [{}], {} font file(s) → {}"
          .format(len(plugin_names), ", ".join(sorted(plugin_names)),
                  ", ".join(sorted(theme_names)),
                  sum(1 for _ in (out / "fonts").rglob("*") if _.is_file()),
                  out))
    if support:
        print("  with support files: {}".format(", ".join(support)))
    return 0


if __name__ == "__main__":
    _force_utf8_stdio()
    sys.exit(main())

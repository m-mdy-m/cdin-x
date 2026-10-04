# CODE_STYLE.md

Code style for cdin-x. Applies to Lua and the two Python scripts. Goal: stable, fast enough, small, readable, typed at the boundaries.

## 1. Formatting

- Lua is formatted by StyLua with the config in section 12. Run it only on files you create or substantially rewrite. Do not reformat a file you only move.
- 2-space indent, no tabs, LF line endings, double quotes, max line length 100.
- One statement per line. No semicolons. No trailing whitespace.
- Python: 4-space indent, standard library only, type hints on every function, max line length 100.

## 2. Naming

| thing | style | example |
| --- | --- | --- |
| file | `snake_case.lua` | `lifecycle.lua`, `safe_path.lua` |
| package name (manifest) | `kebab-case` | `lang-python`, `text-tools` |
| local, function, field | `snake_case` | `load_order`, `resolve()` |
| module table | `M`; class-like objects use `PascalCase` | `Catalog`, `Fetch` |
| constant | `UPPER_SNAKE` | `MAX_MANIFEST_BYTES` |
| private field/function | leading `_` | `_path`, `_resolve_one` |
| boolean | `is_`, `has_`, `can_` | `is_active` |

Names say what a thing is, not how it is built. No abbreviations except `fs`, `cfg`, `opts`, `idx`, `err`, `ok`. No single-letter names outside tiny loops (`i`, `k`, `v`).

## 3. Module structure

Every module has this shape:

```lua
-- Resolves package dependencies and returns a load order.
local Util = require("cdinx.manager.util")

local M = {}

local function visit(...) end

function M.resolve(...) end

return M
```

- One responsibility per file. Target at most 300 lines; above 400, split it.
- The file header comment is the only comment most files have (section 9).
- All `require`s at the top, except a deliberate lazy require inside a function, which is for heavy modules only.
- No globals, no assignment to host tables you do not own. Read host globals (`core`, `PATHSEP`) through one adapter module (`cdinx/host.lua`) so there is one place to change.
- No side effects at require time: no registration, no file or process access, no timers.
- Expose a small public surface. Everything else is `local`.
- Pure logic (resolve, parse, merge, compare) lives apart from IO (fs, process, network). IO is passed in or reached through one thin module, so the logic can be tested later without a running editor.

## 4. Functions

- Do one thing. Target at most 40 lines, at most 4 parameters; beyond that take an options table.
- Early return for the failure and edge paths; the happy path stays flat. Maximum nesting depth 3.
- No hidden state. A function's result depends on its arguments and documented module state only.
- Do not mutate arguments unless the function name says so (`apply_`, `merge_into_`).
- Prefer a numeric `for` or `ipairs` over `pairs` when order matters. Never rely on `pairs` order; sort keys when output order is observable (bundle output, lock files, listings).

## 5. Errors

- Expected failure (missing file, bad input, network down): return `nil, err` with a message that names what, where and why: `"package 'git': dependency 'menu' not found"`.
- Programmer error (wrong type passed to your own API): `error(msg, 2)` or `assert`.
- `pcall` only at boundaries: package `init`, file reads of untrusted content, callbacks from the host. Never swallow an error silently; log it with the package name and keep going.
- Build error messages from `string.format` with `%s` and `tostring()` on anything that might not be a string.
- Failure must leave state consistent. Multi-step changes either complete or are undone (install to a temp directory, then rename; write files to `<name>.tmp`, then rename).

## 6. Types

Type safety is two things: static annotations for the language server, and runtime validation where untrusted data enters.

- LuaLS annotations (`---@class`, `---@param`, `---@return`, `---@alias`, `---@field`) go on the public functions and option tables of each module and on class-like tables. They are type information, not comments, and carry no prose beyond a name and a type. Do not annotate local helpers whose types are obvious.
- Mark nullable explicitly: `string|nil`, `---@return Manifest|nil, string|nil`.
- Return shapes are fixed. A function returns either always a table or `nil, err`; never `false` sometimes and `nil` other times.
- Do not mix types in one table (array and map, strings and numbers as values). Use separate tables.
- Enumerations are constant tables: `local KIND = { PLUGIN = "plugin", LANG = "lang" }`; compare against them, not against string literals scattered through the code.
- Runtime validation happens at the boundary, once: `package.lua`, `packages.lua`, `cdin-x.lock`, `state.lua`, process output, downloaded files. Use the kernel's schema module. After validation, internal code trusts the shape.
- Convert numbers with `tonumber` and check for `nil`. Keep integer and float distinct where it matters.
- `make validate` and the language server (section 12) must report no errors on the files you touch.

## 7. Performance and memory

The editor is interactive. Think about how often a line runs.

**Hot paths** (per keystroke, per frame, per scroll, per draw, per buffer change): no table or closure allocation, no string building by `..` in a loop, no `string.format` for values that are not displayed, no filesystem or process access, no unbounded loops over a buffer.

**Everywhere:**

- Build strings with `table.concat`, not `..` in loops. Use `table.insert(t, v)` or `t[#t + 1] = v`; never `table.insert(t, 1, v)` in a loop.
- Cache hot globals and module functions in locals at module top (`local insert = table.insert`) only when the function is called in a loop or a hot path.
- Do not create closures inside loops; hoist them.
- Never use `#` on a table that can have holes. Keep arrays dense; use `n` fields or separate counters if needed.
- Use weak tables for caches keyed by objects (`setmetatable({}, { __mode = "k" })`). Every other cache has a size or age bound and a clear function.
- Free everything on `unload`: listeners, timers, cached tables, `package.loaded` entries owned by the package. A package that is unloaded must be collectable.
- Read large files in chunks or lines, not whole, unless the size is bounded by a constant you check first.
- Startup loads and parses only enabled packages. Scanning every package happens on demand (panel, refresh) and is cached on disk; invalidate by path, mtime and size.
- Anything that waits (git, network, formatters, docker) is asynchronous through the host's process API. Never block the UI thread.
- Complexity: no O(n²) over packages, buffers or lines when O(n) or O(n log n) is straightforward.
- Measure before optimizing cold paths. Do not skip optimization on hot paths because "it's probably fine".

Choosing between options: pick the one with predictable cost and fewer moving parts. A cache that can go stale is a liability; add one only when the uncached cost is measured or obviously large, and give it an invalidation rule.

## 8. Host interaction

- Extend the host through its registries (commands, keymap, menus, hooks when available). Do not edit host tables directly.
- If the host offers no seam and you must wrap a function, use the shared wrapper utility that stores the original and restores it in `unload`. Wrapping a function twice from two packages must still unwind correctly.
- Never assume a host function exists. Check for it once at `init`, and disable the feature with a reason if it is missing.
- Never use absolute paths or the host install layout. Resolve paths through `cdinx/config.lua` and the host's own resolvers. Separators come from `PATHSEP`, never a literal `/` or `\` in joined paths.

## 9. Comments

Comments are rare. The code should read without them.

- **File header:** one to three lines saying what the file does. Nothing else about history, authors or design essays.

  ```lua
  -- Reads and validates package.lua files in a sandbox.
  ```

- **Allowed, one line each, only when needed:** a non-obvious reason (a workaround, a platform quirk, an invariant that the code cannot show). Say why, never what.
- **Not allowed:** comments that restate code, banners and section dividers, commented-out code, TODO/FIXME without being asked, changelog or history notes, multi-paragraph explanations, emoji.
- LuaLS annotations (section 6) are not comments for this rule.
- When you move or substantially edit an old file, replace its long explanatory comment with the header plus the few one-line "why" notes that still matter. Keep any warning about a real platform or host quirk. Do not rewrite comments in files you only move.
- Docs, tests and changelog are the owner's job, later.

## 10. Do not

- globals, `setfenv`, `loadstring` of arbitrary text, `os.execute`/`io.popen` with unescaped input;
- `pcall(require, ...)` to detect optional packages (use the manager's `is_active(name)`);
- string-typed flags and magic numbers in logic;
- deep inheritance, metatable magic, operator overloading;
- functions that both compute and perform IO;
- silent fallbacks that hide a failure;
- dependencies on the current working directory;
- copying large code blocks instead of extracting a shared function (after the third copy).

## 11. Edge-case checklist

Walk through this list before writing code and after. Handle in code; report in the final message (not in comments or files).

**Input:** nil, empty string, empty table, wrong type, very long input, malformed or truncated file, unexpected extra fields, duplicate keys.

**Text:** UTF-8 multi-byte characters (this editor targets Arabic and Persian, so right-to-left text, combining marks and shaping are real); never use `#` for display width or character count; use `utf8` functions. CRLF and LF. BOM. Invalid UTF-8 bytes. Trailing newline or none.

**Filesystem:** missing file or directory, permission denied, path with spaces or non-ASCII characters, Windows separators and drive letters, trailing separators, `..` and absolute paths in untrusted input (path traversal), symlinks and symlink loops, case-insensitive filesystems, read-only or full disk, very deep or very large directories, a file that changes between check and use.

**State and lifecycle:** `init` called twice, `unload` before `init`, `unload` twice, reload of a loaded module, a callback that fires after unload, partial failure in the middle of `init`, a dependency that fails to load, cycles in dependencies, a disabled dependency of an enabled package, an empty bundle, name collisions between packages, invalid version strings or ranges.

**Concurrency and time:** two editor instances writing the same state or lock file, an interrupted download or install, timeouts, retries that are not idempotent, clocks that go backwards.

**Network and processes:** no network, proxy failures, redirects, truncated downloads, non-zero exit codes, very large output, a missing external executable, a process that never exits.

**Resources:** unbounded growth of caches, logs, histories and listeners; handles not closed on error paths.

## 12. Tooling configuration

Add these files at the repository root if they do not exist. Verify option names against the installed tool versions.

`stylua.toml`

```toml
column_width = 100
line_endings = "Unix"
indent_type = "Spaces"
indent_width = 2
quote_style = "AutoPreferDouble"
call_parentheses = "Always"
collapse_simple_statement = "Never"
```

`.luarc.json` (LuaLS; run `lua-language-server --check . --checklevel=Warning`)

```json
{
  "runtime.version": "Lua 5.4",
  "workspace.library": [],
  "diagnostics.globals": [],
  "diagnostics.groupSeverity": { "strong": "Error", "type-check": "Error", "strict": "Warning" },
  "diagnostics.groupFileStatus": { "strong": "Any", "type-check": "Any", "strict": "Any" },
  "hint.enable": false
}
```

`.luacheckrc`

```lua
std = "lua54"
max_line_length = 100
globals = {}
read_globals = {}
```

Fill `read_globals` and `diagnostics.globals` only with host-provided globals confirmed from the cdin source (for example `PATHSEP`). Anything else that appears as an undefined global is a bug to fix, not a setting to add.
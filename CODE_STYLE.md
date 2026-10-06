# CODE_STYLE.md

Code style for cdin-x. Applies to Lua 5.4 and the Python scripts. It extends cdin's own style (`snake_case` everywhere, modules return tables, classes extend `core.utils.object`, locals only). Goal: stable, fast enough, small, readable, typed at the boundaries.

## 1. Formatting

- Follow `.editorconfig`: UTF-8, LF, final newline, trailing whitespace trimmed, 2-space indent (Makefiles use tabs).
- Lua is formatted by StyLua with the config in section 12. Run it only on files you create or substantially rewrite. Do not reformat a file you only move.
- Double quotes, max line length 100, one statement per line, no semicolons.
- Python: 4-space indent, standard library only, type hints on every function, max line length 100.

## 2. Naming

| thing | style | example |
| --- | --- | --- |
| file | `snake_case.lua` | `lifecycle.lua`, `safe_path.lua` |
| package name (manifest) | `kebab-case` | `lang-python`, `text-tools` |
| local, function, field | `snake_case` | `load_order`, `resolve()` |
| module table | `M`, or `PascalCase` for a named module table | `Catalog`, `Fetch` |
| class (instances, `:new`) | extend `core.utils.object`: `local Panel = Object:extend()` | `Panel` |
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
- No globals. Under `core.runtime.strict` an undeclared global raises. Read host-provided globals (`core`, `PATHSEP`, `VERSION`, `SCALE`, `system`, `renderer`) and the host modules (`core`, `core.fs`, `core.config`) through one adapter module (`cdinx/host.lua`) so there is one place to change. Every kernel module does; `host.lua`, `config.lua` and `schema.lua` are the three exceptions and each says why in its header. The searcher in `loader.lua` reads its tables through the shared `package.cdinx_store` on every call for the same reason: a captured local goes stale the first time `ensure` replaces the table.
- No side effects at require time: no registration, no file or process access, no timers. `core.reload_module` folds new fields into the old table without undoing registrations, so top level is declarations and `init()` does the registering.
- Expose a small public surface. Everything else is `local`.
- Pure logic (resolve, parse, merge, compare) lives apart from IO (fs, process, network). IO is passed in or reached through one thin module, so the logic can be tested later without a running editor.
- Entry points tolerate `init` being called twice and `unload` being called without `init`.

## 4. Functions

- Do one thing. Target at most 40 lines, at most 4 parameters; beyond that take an options table.
- Early return for the failure and edge paths; the happy path stays flat. Maximum nesting depth 3.
- No hidden state. A function's result depends on its arguments and documented module state only.
- Do not mutate arguments unless the function name says so (`apply_`, `merge_into_`).
- Never rely on `pairs` order. Sort keys when output order is observable (bundle output, lock files, listings, the panel).

## 5. Errors

- Expected failure (missing file, bad input, network down): return `nil, err` with a message that names what, where and why: `"package 'git': dependency 'menu' not found"`.
- Programmer error (wrong type passed to your own API): `error(msg, 2)` or `assert`.
- `pcall` (or `core.try`) only at boundaries: package `init`/`unload`, reads of untrusted content, callbacks from the host. Never swallow an error silently; log it with `core.log` or `core.error`, naming the package, and keep going.
- Build messages with `string.format` and `tostring()` on anything that might not be a string.
- Failure must leave state consistent. Multi-step changes either complete or are undone (install into a temp directory, then rename; write `<name>.tmp`, then rename).

## 6. Types

Type safety is two things: static annotations for the language server, and runtime validation where untrusted data enters.

- LuaLS annotations (`---@class`, `---@param`, `---@return`, `---@alias`, `---@field`) go on the public functions and option tables of each module and on class-like tables. They are type information, not comments, and carry no prose beyond a name and a type. Do not annotate local helpers whose types are obvious.
- Mark nullable explicitly: `string|nil`, `---@return Manifest|nil, string|nil`.
- Return shapes are fixed. A function returns either always a value or `nil, err`; never `false` sometimes and `nil` other times.
- Do not mix types in one table (array and map, strings and numbers as values).
- Enumerations are constant tables (`local KIND = { PLUGIN = "plugin", LANG = "lang" }`); compare against them, not against string literals scattered through the code.
- Runtime validation happens at the boundary, once: `package.lua`, `packages.lua`, `cdin-x.lock`, state files, process output, downloaded files. Use the kernel's schema module. After validation, internal code trusts the shape.
- Convert numbers with `tonumber` and check for `nil`. Keep integer and float distinct where it matters (Lua 5.4).
- The language server (section 12) and `make validate` must report no errors on the files you touch.

## 7. Performance and memory

The editor is interactive. Think about how often a line runs.

**Hot paths** (per keystroke, per frame, per scroll, per draw, per buffer change; anything reachable from `update`/`draw`/`on_key_pressed`/`on_text_input`): no table or closure allocation, no string building by `..` in a loop, no `string.format` for values that are not displayed, no filesystem or process access, no unbounded loops over a buffer.

**Everywhere:**

- Build strings with `table.concat`, not `..` in loops. Use `t[#t + 1] = v`; never `table.insert(t, 1, v)` in a loop.
- Cache hot globals and module functions in locals at module top only when the function is called in a loop or a hot path.
- Do not create closures inside loops; hoist them.
- Never use `#` on a table that can have holes. Keep arrays dense.
- Use weak tables for caches keyed by objects (`setmetatable({}, { __mode = "k" })`). Every other cache has a size or age bound and a clear function.
- Free everything on `unload`: commands, keymaps, providers, panels, pills, hooks, threads, cached tables, `package.loaded` entries owned by the package. An unloaded package must be collectable. Tie threads to their owner with `core.add_thread(fn, weak_ref)`.
- Read large files in chunks or lines, not whole, unless the size is bounded by a constant you check first (`config.file_size_limit` exists for documents).
- Startup loads and parses only enabled packages. Scanning every package happens on demand (panel, refresh), in a coroutine that yields every few dozen entries so a frame is never starved, and is cached on disk; invalidate by path, mtime and size.
- Never block the frame loop. `system.popen` blocks until the process exits: use it only for commands known to finish instantly with bounded output. For anything that waits (git, network, tar, formatters) start a detached job with `system.exec` and poll it from a `core.add_thread` coroutine, as `cdinx/manager/fetch.lua` does.
- Complexity: no O(n²) over packages, buffers or lines when O(n) or O(n log n) is straightforward.
- Measure before optimizing cold paths. Do not skip optimization on hot paths because "it's probably fine".

Choosing between options: pick the one with predictable cost and fewer moving parts. A cache that can go stale is a liability; add one only when the uncached cost is measured or obviously large, and give it an invalidation rule.

## 8. Host interaction

- Use the documented seams first (see `AGENTS.md`): `Doc._before_save`/`_after_save`/`_after_load` lists rather than wrapping `Doc.save`; `attach_side_view` rather than splitting the active node; `themes.add_root`; `core.register_*` providers.
- If no seam exists and you must wrap a function, wrap the outermost one, save the original, call it, and restore it in `unload`. A wrapper that leaks runs again on the next load.
- `command.add` asserts on a duplicate name unless `overwrite` is passed; `keymap.add` prepends unless `overwrite` is passed. Write the second argument at every call site. Never pass `overwrite` to a stroke that is gated by a predicate. On `remove`, hand back the same table you added.
- Keystroke strings are matched exactly: lowercase, modifiers in `ctrl+alt+altgr+shift` order, joined by `+`. Anything else is a dead binding.
- Never assume a host function exists. Check once at `init` and disable the feature with a logged reason if it is missing. `core.register_vcs_provider` is not available during `init`.
- Never use absolute paths or the host install layout. Resolve paths through `config.site_path()` and `core.fs`. Separators come from `PATHSEP` or `fs.join`, never a literal `/` or `\` in joined paths.

## 9. Comments

Comments are rare. The code should read without them.

- **File header:** one to three lines saying what the file does. Nothing else about history, authors or design essays.

  ```lua
  -- Reads and validates package.lua files in a sandbox.
  ```

- **Allowed, one line each, only when needed:** a non-obvious reason (a workaround, a platform quirk, an invariant that the code cannot show). Say why, never what.
- **Not allowed:** comments that restate code, banners and section dividers, commented-out code, TODO/FIXME unless asked, changelog or history notes, multi-paragraph explanations, emoji.
- LuaLS annotations (section 6) are not comments for this rule.
- Much existing code in this repository carries long essay comments. When you move or substantially edit a file, replace the essay with the header plus the few one-line "why" notes that still matter, and keep every warning about a real host or platform quirk. Do not rewrite comments in files you only move.
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

**Text:** UTF-8 multi-byte characters. This editor targets right-to-left scripts (Arabic, Persian), so bidi, combining marks and shaping are real: never use `#` for display width or character count; use `core.text.utf8` or the `utf8` library. CRLF and LF. BOM. Invalid UTF-8 bytes. Trailing newline or none.

**Filesystem:** missing file or directory, permission denied, paths with spaces or non-ASCII characters, Windows separators and drive letters, trailing separators, `..` and absolute paths in untrusted input (path traversal), symlinks and junctions and loops, case-insensitive filesystems, read-only or full disk, very deep or very large directories, a file that changes between check and use.

**State and lifecycle:** `init` called twice, `unload` before `init`, `unload` twice, reload of a loaded module (`core.reload_module` keeps old registrations), a callback or thread that fires after unload, partial failure in the middle of `init`, a dependency that fails to load, cycles, a disabled dependency of an enabled package, an empty bundle, name collisions between packages or with host modules, invalid version strings or ranges, a registration that has no `remove` in the host (`syntax.add`, `register_vcs_provider`).

**Concurrency and time:** two editor instances writing the same state or lock file, an interrupted download or install, timeouts, retries that are not idempotent, clocks that go backwards.

**Network and processes:** no network, proxy failures, redirects, truncated downloads, non-zero exit codes, very large output, a missing external executable, a process that never exits, a detached job that outlives the editor.

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
  "diagnostics.globals": ["core", "system", "renderer", "EXEDIR", "EXEFILE", "PATHSEP", "PLATFORM", "VERSION", "ARGS", "SCALE"],
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
read_globals = { "core", "system", "renderer", "EXEDIR", "EXEFILE", "PATHSEP", "PLATFORM", "VERSION", "ARGS", "SCALE" }
```

Confirm the global list against cdin's `data/core/init.lua` and `core/runtime/strict.lua`. Any other undefined global is a bug to fix, not a setting to add.
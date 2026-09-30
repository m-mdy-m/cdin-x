# Adding a syntax definition

```text
X/syntax/<language>.lua
```

One file per language, named for the language. No commands, no keys, and no
dependency beyond the host — which is why it gets its own category instead of
being a `core/` plugin: there is nothing to load and nothing to unload.

Six ship here: `c`, `javascript`, `lua`, `markdown`, `python`, `typescript` —
and they claim disjoint extensions, so a `.ts` file is never picked up by the
JavaScript definition. See the table below.

## The fastest way

```lua
-- ~/.config/cdin/user/init.lua
require("core.syntax").add {
  files = "%.zig$",
  patterns = {
    { pattern = { '"', '"', '\\' }, type = "string" },
    { pattern = "%-%-.*",          type = "comment" },
    { pattern = "0x%x+",            type = "number" },
    { pattern = "[%a_][%w_]*",     type = "symbol" },
  },
  symbols = { ["fn"] = "keyword", ["const"] = "keyword" },
}
```

No manifest, no directory, no `make validate`. The host matches the active
document's filename against `files` and uses the first definition that claims
it, so order matters if you have several.

## To add it to the catalog

Copy `X/syntax/lua.lua`, change the name, the description, the `files` pattern
and the patterns. Then:

```sh
make manifest
make validate
```

## The shape

```lua
return {
  name = "zig",
  version = "0.1.0",
  description = "Zig syntax support",
  category = "syntax",
  type = "plugin",
  essential = false,
  dependencies = {},
  tags = { "language", "zig" },

  init = function(core, config)
    require("core.syntax").add {
      files   = "%.zig$",              -- which files this claims
      headers = "^#!.*[ /]zig",        -- a shebang, for extensionless files
      comment = "--",                  -- for commenting out a line

      patterns = {
        -- order matters: first match wins
        { pattern = { '"', '"', '\\' }, type = "string" },
        { pattern = "%-%-.*",           type = "comment" },
        { pattern = "0x%x+",            type = "number" },
        { pattern = "[%a_][%w_]*",     type = "symbol" },
      },

      symbols = {                       -- a set keyed by word
        ["fn"]    = "keyword",
        ["const"] = "keyword",
        ["true"]  = "literal",
      },
    }
  end,

  unload = function() end,
}
```

### `files` and `headers`

`files` is a **Lua pattern, or a list of them**, matched anywhere in the
filename. Not a glob, not an extension.

```lua
files = "%.lua$"                              -- one pattern
files = { "%.ts$", "%.d.ts$", "%.tsx$" }     -- any of these
```

The dot has to be escaped and the end anchored, or `%.js` also matches
`foo.js.bak`. A list is not an alternation — it is several patterns tried in
order, first match winning, and it exists because most languages have more than
one extension and writing `%.ts$|%.tsx$` is a pattern nobody can read.

Six definitions ship, and they claim disjoint extensions:

| definition | claims |
| --- | --- |
| `c` | `.c` `.h` `.inl` `.cpp` `.hpp` |
| `javascript` | `.js` `.json` `.cson` |
| `typescript` | `.ts` `.d.ts` `.tsx` |
| `lua` | `.lua` |
| `python` | `.py` |
| `markdown` | `.md` `.markdown` |

**`headers` is the same idea for files with no useful extension** — a
shebang, matched against the first line, for a `#!/usr/bin/env python` script
that is a Python file whatever it is called.

**A file with no definition is plain text, and nothing warns you.** Which is why
"my language is not highlighted" is nearly always a `files` pattern that does
not match, rather than a missing definition.

### `patterns`

A list, tried in order, **first match wins**. That is why the string rules come
first in every definition in the catalog: a `"` inside a comment must be a
comment, and if the comment rule were below the string rule it would be a
string.

A pattern is either a string or a three-element table:

| form | means |
| --- | --- |
| `pattern = "…"` | a Lua pattern, from the start of the line |
| `pattern = { open, close }` | a delimited span |
| `pattern = { open, close, escape }` | a delimited span where `escape` escapes |

So `{ '"', '"', '\\' }` is a double-quoted string where `\` escapes the next
character, and `{ "%[%[", "%]%]" }` is a Lua long string — which is why the
brackets are escaped: inside a `char class`, `[` has to be `%[`.

`type` is one of `string`, `comment`, `number`, `keyword`, `keyword2`, `literal`,
`operator`, `function`, `symbol`, `normal`. **These are exactly the keys under
`syntax` in a theme**, which is the whole contract between a language definition
and a colour scheme. A `type` a theme has no key for falls back to `normal`, so
a typo is invisible rather than fatal.

Two patterns worth copying, because they are the ones you will want:

```lua
-- a function call: an identifier immediately followed by (
{ pattern = "[%a_][%w_]*%s*%f[(\"{]", type = "function" },

-- an operator: every character, one at a time
{ pattern = "[%+%-=/%*%^%%#<>]", type = "operator" },
```

The `%f[%a]`-style frontier in the first one is what makes it match the
*identifier* and stop before the paren, rather than swallowing the paren too.
Without it you get a function name that ends in a bracket.

### `symbols`

A set of words, keyed by the word, valued by its type. It is checked **after**
the patterns, which is why `symbols` cannot contain anything a pattern would
have claimed first — and why `"function"` in Lua's `symbols` colours as a
keyword even though `%a_[%w_]*` would have matched it as a symbol.

`symbols` is a set rather than a list because that is what a hand-written
definition reads like, and because duplicate keys in a Lua table constructor are
a silent last-wins rather than an error.

## How it works

**Definitions are a list, and the last one registered wins.** `syntax.add`
appends, and the lookup walks the list **backwards** and returns the first match
it finds. So a definition you add from your `init.lua` overrides a catalog
one — which is what you want, and also means a second `add` for the same
extension silently replaces the first.

**A definition is chosen by filename when the document loads, and cached with
it.** Changing a file's extension on disk is not something the editor notices;
reload the document and it re-reads.

**Only the visible lines are highlighted.** There is a `max_wanted_line` and a
`first_invalid_line`, and the highlighter works outward from what is on screen.
That is why opening a very large file is instant, and why scrolling into new
territory is where you notice a slow pattern — a pathological Lua pattern on a
long line is the one place highlighting can cost you a frame.

**The types a pattern emits are the theme's `syntax` keys, and nothing else in
the editor knows what they mean.** `source.lua` and `suggest.lua` decide which
type a span gets; a theme decides what colour that type is. A `type` a theme has
no key for falls back to `normal`, so a typo is invisible rather than fatal.

**There is no `syntax.remove`.** So `unload` is empty in all six definitions,
and that is not an oversight — there is nothing to call. A definition added from
your `init.lua` lasts for the session, which is exactly what you wanted when
you added it there.

## Writing patterns that do not lie

A pattern that matches too much is worse than no pattern, because the text it
claims is text you cannot read. Three habits:

**Anchor what must be anchored.** `"//.*"` is fine; `"//.*"` without a boundary
is the same thing here, but `".*//.*"` would match every line.

**Put longer alternatives first.** `{ "[%a_][%w_]*", type = "symbol" }` before
`{ "[%a_][%w_]*%s*(%b())", type = "function" }` gives you every identifier as a
symbol and no function names. The order is the pattern.

**Test on a real file, not on one line.** A definition that looks right on
`local x = 1` is not evidence about a file with a URL in a comment, and the URL
is where you will find out.

## Files

| file | holds |
| --- | --- |
| `X/syntax/<language>.lua` | the definition |
| `../../data/core/doc/highlighter.lua` | the walker, in the cdin repository |
| `../../data/core/syntax.lua` | `syntax.add`, and the filename matching |

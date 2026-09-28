# autocomplete

Completion popup fed by *providers*.

The default provider offers symbols taken from every open document, so
typing three characters of a name you have seen anywhere in the project is
enough. Anything else is added as another provider.

## Adding a provider

```lua
require("X.core.autocomplete.api").add {
  name  = "lua-keywords",   -- replaces a provider of the same name
  files = "%.lua$",         -- optional; defaults to every file
  items = { "function", "end", "local" },
}
```

`items` is either a list of `{ text, info }` entries or a set keyed by text
(`{ foo = "some info" }`), which is what the built-in symbol scanner
produces. Replacing a provider of the same name is how a provider refreshes
its contents.

The registry is also published as `core.autocomplete` once the plugin is
loaded, so a user config can reach it without the module path.

## Layout

| file | role |
|---|---|
| `api.lua` | provider registry, suggestion state, load point |
| `source.lua` | the built-in provider: open-document symbols |
| `suggest.lua` | fuzzy matching, dedup, current suggestion list |
| `popup.lua` | geometry and drawing of the box |
| `commands.lua` | complete / previous / next / cancel |
| `keymap.lua` | Tab, Up, Down, Escape |

## Commands

`autocomplete:complete`, `autocomplete:previous`, `autocomplete:next`,
`autocomplete:cancel` — all predicated on a suggestion being visible, so
the keys fall through to their normal meaning when the popup is not up.

## Scanning

Symbols are collected on a coroutine, so a large project never blocks a
frame. Each document's symbol set is cached against its change id, and an
unchanged document is not re-scanned on every pass. The cache is
weak-keyed, so closing a document drops it.

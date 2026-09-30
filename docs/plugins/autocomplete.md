# autocomplete

Symbol completion for open documents.

Type three characters and a list appears. <kbd>Tab</kbd> takes the highlighted
one, <kbd>↑</kbd> and <kbd>↓</kbd> move, <kbd>Esc</kbd> dismisses.

| key | does |
| --- | --- |
| <kbd>Tab</kbd> | `autocomplete:complete` |
| <kbd>↑</kbd> / <kbd>↓</kbd> | `autocomplete:previous` / `:next` |
| <kbd>Esc</kbd> | `autocomplete:cancel` |

The commands are **predicated on a suggestion being visible**, so all four
strokes fall through to their normal meaning when the popup is not up. <kbd>Tab</kbd>
indents, <kbd>↑</kbd> and <kbd>↓</kbd> move the cursor, <kbd>Esc</kbd> deselects.
That is the whole design in one sentence: a popup that steals keys is a popup
you will turn off.

Three characters is the threshold. Fewer and there is nothing to narrow.

## Adding a provider

A provider supplies items. Nothing here knows where they came from, and the
popup fuzzy-matches whatever it is handed against what you have typed.

```lua
local ac = require "X.core.autocomplete.api"

ac.set {
  name  = "my-language",      -- or just ac.set("my-language", …)
  files = "%.lua$",           -- optional; applies everywhere if absent
  items = {                   -- a set keyed by text, or a list of items
    ["myFunction"] = "from my-language",
  },
}
```

| what | does |
| --- | --- |
| `set(spec)` | register, or replace a provider of the same name |
| `add(spec)` | the same, under its original name — kept working |
| `remove(name)` | drop one |
| `clear()` | drop all of them |
| `provider_names()` | what is registered, sorted |
| `reset()` | forget the current suggestion list |

`items` takes either shape on purpose: a **set keyed by text** is what the
built-in symbol scanner produces, and a **list of `{ text, info }`** is what a
hand-written provider reads more naturally. Both end up as the same internal
item, so the two kinds of provider are not two kinds of thing downstream.

**`files` is a pattern matched against the active document's filename.** A
provider with no pattern applies everywhere. This is the mechanism that lets a
language plugin claim "only in `.ts` files" without this plugin knowing that
TypeScript exists.

**Replacing a provider of the same name is how it refreshes.** The built-in one
does exactly that on every rescan, which is why there is no separate "update"
call.

**`autocomplete_max_suggestions` is 6, and it is a real setting.** Unlike most
plugin defaults, this one lands in the host's `config` table, so
`config.autocomplete_max_suggestions = 10` in your `init.lua` does something.

## How it works

```text
api.lua      the provider registry, and the public surface
source.lua   the built-in provider: symbols from every open document
suggest.lua  matching, dedup, and the current suggestion list
popup.lua    geometry and drawing
commands.lua accept / previous / next / cancel
keymap.lua   Tab, Up, Down, Escape
```

**Symbols come from open documents only.** Not the project, not the disk. A
per-keystroke project scan would be a stall, and a completion list full of
symbols you cannot see is worse than a short accurate one.

**The popup is drawn by deferring, and driven by wrapping three methods.** The
editor has no event system, so `RootView.on_text_input`, `RootView.update` and
`RootView.draw` are each wrapped, the original called, and the originals put
back on unload. That is the pattern this whole repository uses for extending the
runtime, and autocomplete is the clearest example of why: the alternative would
be a core that knows about completion.

**`ITEM_MT` exists so `tostring` returns the text.** The fuzzy matcher scores
`tostring(item)`; without the metatable it would score the table's *address*,
and every candidate would score identically. It is exported because `suggest.lua`
folds a run of equal items into one merged entry, and that merged entry has to
be the same shape as the ones it replaces — a second metatable would be a second
thing to keep in step.

**The popup is kept on screen.** After a keystroke, if the box would run off the
bottom of the view, the view scrolls to compensate. A completion list that
disappears under the cursor at the last line of a file is the kind of small
wrongness that makes a feature feel haunted.

**`api.lua` is not `init.lua`.** The manager `dofile`s the entry point, and a
plugin whose entry point is also its API ends up with two half-initialised
copies. Every plugin with a public surface keeps it in its own file. See
[git](git.md) for the full explanation — it is the one structural rule in the
catalog that has no `validate` check behind it.

## Files

| file | holds |
| --- | --- |
| `api.lua` | the provider registry, the state, the three wrapped methods |
| `source.lua` | the built-in symbol provider |
| `suggest.lua` | matching, dedup, the current list |
| `popup.lua` | geometry and drawing |
| `commands.lua` | accept / previous / next / cancel |
| `keymap.lua` | Tab, Up, Down, Escape |

# The optional plugins

Three. None of them is part of a cdin build — only `vim`, `manager` and the `default`
theme are — and all three are installed from the manager like anything else.

## rtl_toggle

Right-to-left text, and Arabic shaping, switchable at runtime.

| key | does |
| --- | --- |
| <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>R</kbd> | `rtl:toggle-direction` — cycles `auto` → `ltr` → `rtl` |
| <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>S</kbd> | `rtl:toggle-shaping` — shaping on its own |

`auto` follows the document's own detected direction, which is what you want
almost always; the other two override it. Shaping is the joining of Arabic
letters into connected forms, and it is separate from direction because they go
wrong independently — a document can be laid out right-to-left with no shaping,
and shaped with no right-to-left.

The starting value is read from `config.direction`, so this is one of the few
plugin defaults you can actually set:

```lua
-- ~/.config/cdin/user/init.lua
config.direction = "rtl"
config.shaping_enabled = false
```

Both are applied with `~= false` rather than assigned, so a `nil` from an older
config file does not turn a feature off.

## theme_switcher

Pick a theme from a list, and keep the choice.

| key | does |
| --- | --- |
| <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>T</kbd> | `core:change-theme` |

Ten themes ship in the catalog. This is the UI for choosing between them, and
`session-theme-switcher` is what makes the choice survive a restart — they are
separate plugins because "change it now" and "remember that I did" are separate
questions, and some people want the first without the second.

**To add a theme of your own, you do not need this plugin.** A theme is a
directory with a `theme.lua` in it, and cdin's registry reads any root you give
it. See [adding a theme](../building/a-theme.md).

## unicode_inspect

Shows the code points under the cursor, or across the selection.

| key | does |
| --- | --- |
| <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>U</kbd> | `unicode:inspect` |

With a selection, it decodes the whole thing. With a single caret, it decodes
the one character — by reading its **first byte** and inferring the length from
it (`0xF0` → 4 bytes, `0xE0` → 3, `0xC0` → 2), which is the standard trick and
is correct for every well-formed sequence.

It is scoped to a document view, so it is only offered when there is a document
to inspect, and it prints at most 32 code points with a byte count if the
UTF-8 helper is unavailable — rather than showing you nothing and an error.

Output is `U+0041 U+00E9 …` with a character count, which is the form you can
paste into a search engine.

## Files

One directory each, two files: `init.lua` (manifest and lifecycle) and
`impl.lua` (the plugin). Small enough that a third file would be worse than a
long one.

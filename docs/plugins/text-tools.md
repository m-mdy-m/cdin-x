# text-tools

Two conveniences for working with text that is not English: one changes how text
is laid out, the other tells you what the bytes are. They share a package and
nothing else, so each is a feature and either can be off alone.

| feature | what it does |
| --- | --- |
| `rtl` | right-to-left layout and Arabic shaping, switchable at runtime |
| `unicode` | show the codepoints of the selection, or of the character at the caret |

## rtl

| key | does |
| --- | --- |
| <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>R</kbd> | `rtl:toggle-direction` — cycles `auto` → `ltr` → `rtl` |
| <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>S</kbd> | `rtl:toggle-shaping` — shaping on its own |
| <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>U</kbd> | `unicode:inspect` — see below |

`auto` follows the document's own detected direction, which is what you want
almost always; the other two override it. Shaping is the joining of Arabic letters
into connected forms, and it is separate from direction because they go wrong
independently — a document can be laid out right-to-left with no shaping, and
shaped with no right-to-left.

### The starting value is yours

```lua
-- ~/.config/cdin/user/init.lua
config.direction = "rtl"
config.shaping_enabled = false
```

The toggle derives its position from `config.direction` **when the feature is
enabled**, so a direction you set in `init.lua` is where the first press starts
from rather than being overwritten by it.

That was not always so. The index used to be fixed at `1`, and the first press
wrote `config.direction` unconditionally — so a user who had set it in `init.lua`
lost it on the first <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>R</kbd> and could not get
it back for the rest of the session.

**Only `shaping_enabled` is guarded against `nil`.** It is applied with
`~= false` rather than assigned, so a value an older config file never set reads
as off, and the first press turns it *on* instead of turning `nil` into `false`
and looking like nothing happened.

### These are the host's config keys

`config.direction` is what the renderer reads to lay a line out, and
`config.shaping_enabled` is what the text layer reads to shape Arabic. They are
written at the top level of `config` and **not** namespaced under the package:

```lua
config.direction = "rtl"     -- right
config.text_tools.direction = "rtl"   -- a key nothing reads
```

The second one would look configured and change nothing, which is exactly what
declaring the keys as *host* config rather than package options is for.

## unicode

| key | does |
| --- | --- |
| <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>U</kbd> | `unicode:inspect` |

With a selection it decodes the whole thing. With a single caret it decodes the
one character — by reading its **first byte** and inferring the length from it
(`0xF0` → 4 bytes, `0xE0` → 3, `0xC0` → 2), which is the standard trick and is
correct for every well-formed sequence.

It is scoped to a document view, so it is only offered when there is a document to
inspect, and it prints at most 32 code points — with a byte count if the UTF-8
helper is unavailable, rather than showing you nothing and an error.

Output is `U+0041 U+00E9 …` with a character count, which is the form you can
paste into a search engine.

**`core.text.utf8` is required inside the handler, not at the top.** It is a
decode-and-measure module, and this package does nothing without a keystroke, so
loading all of it on every editor start would be a cost with no reader. A host
without it is not an error either — the handler falls back to printing the byte
count, which is still what someone debugging an encoding problem needs.

## Switching features off

```lua
return {
  features = {
    ["text-tools"] = { unicode = false },
  },
}
```

The package name has a hyphen, so it needs the bracket form in Lua. That is not a
special case the package asks for — it is what makes `text-tools` a valid
`require` name and a valid directory name at the same time, which is the same
trade as `core.rootview` and `core.docview`.

## Files

```text
init.lua                package lifecycle only
features/rtl.lua        the two toggles
features/unicode.lua    the inspector
```
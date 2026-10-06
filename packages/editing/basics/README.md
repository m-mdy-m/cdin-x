# basics

Two conveniences that have nothing in each other's way and always travel
together:

- **autoreload** — a document reloads when its file changes underneath the editor.
  A thread polls the open documents' timestamps. Off by turning the feature off.
- **trimwhitespace** — trailing whitespace is trimmed before every save, and
  `trim-whitespace:trim-trailing-whitespace` does it on demand.

Both are features, so either can be switched off on its own:

```lua
-- in ~/.config/cdin/user/init.lua, or through the Extensions panel
require("cdinx").set_features("basics", { trimwhitespace = false })
```

The command in `trimwhitespace` is bound only while that feature is on. Nothing
here registers a keystroke.
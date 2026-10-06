# text-tools

For working with text that is not English.

- **rtl** — <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>R</kbd> cycles the text direction
  through `auto`, `ltr` and `rtl`; <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>S</kbd> turns
  Arabic shaping on and off. Writes `config.direction` and
  `config.shaping_enabled`.
- **unicode** — <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>U</kbd> logs the codepoints of
  the selection, or of the one character at the caret when nothing is selected.
  Shows at most 32 of them and then the total, so a whole-file selection does not
  fill the log.

Each is a feature, so either can be switched off on its own. The keystrokes are
bound only while the feature that owns them is on.

## Why `rtl` writes `config.direction` and not something of its own

Those two keys are read by the host — the renderer for `direction`, the text layer
for `shaping_enabled`. They are not package options and they are not namespaced,
because `config.text_tools.direction` would be a key nothing reads: the feature
would look like it worked and change nothing. `options` in `package.lua` is for
values only this package reads.
# X integrations

Integration plugins connect two or more otherwise independent X plugins.

The rule is simple:

- `X/core/<plugin>` owns one capability and must not depend on another X plugin.
- `X/integration/<plugin>` owns the wiring between capabilities.
- Integration dependencies are declared in the manifest.
- Prefer one integration per meaningful relationship, not dozens of one-off hooks.
- UI providers should depend on generic primitives such as `menu`, not implement their own menu engine.

A category may group its plugins one level deeper, as `X/integration/vim/`
does. The scanner descends into a directory that is not itself a plugin, and
installing preserves the layout, so the grouping level never changes the
module names a plugin uses to address another.

## Shape

```text
X/integration/<ns>/<name>/
  init.lua        manifest + register/unregister of the siblings
  commands.lua    ex-commands or cdin commands      (register/unregister)
  keymap.lua      key bindings                      (register/unregister)
  *.lua           whatever else the wiring needs
```

`init.lua` requires its siblings **inside `init()`**, never at module scope:
the catalog reads `init.lua` with `dofile()` to discover the manifest, so a
top-level `require` would run the whole subtree's side effects just to look
the plugin up. It is also not the module other plugins require — see
`X/README.md`.

An integration with nothing but a subscription (no commands, no keys) is
still a legitimate integration: `X/integration/session/theme-switcher`
exists only to connect two plugins that must not know about each other.

## Current integrations

- `git-treeview`: Git status → Treeview badges/refresh.
- `tab-session`: tab manager + persistent session state.
- `session/theme-switcher`: theme switcher → session theme persistence.
- `vim-git`: Vim mode → Git commands/menu.
- `vim-menu`: Vim mode → the generic menu, and the `m` key.
- `vim-plugin-manager`: Vim mode → the CDIN-X extension manager, and `M`.
- `vim-search`: Vim mode → Search plugin, and `/ n N *`.
- `vim-tab`: Vim mode → Tab manager, `:tabnew`… and `gt`/`gT`.
- `vim-treeview`: Vim mode → Treeview + menu, and `:tree`.
- `vim-window`: Vim mode → Window manager, `:split`…, `Ctrl+W` and `Tab`.

The `vim-*` plugins all extend vim through one registry,
`X.core.vim.registry` — see `X/core/vim/README.md` for the full table of
extension points and a worked example.

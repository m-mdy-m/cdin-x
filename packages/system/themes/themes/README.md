# themes

```text
<themes>/<name>/theme.lua
```

One directory per theme, one file in it, a table of colours. That is the layout
cdin's theme registry reads, so a theme directory can be handed to
`core.themes.add_root()` as-is — which is what a user does to add their own
without installing anything.

Ten here, and nothing in any of them says which of them a build carries. That is
`bundles/standard.lua`, which names the `themes` *package* rather than the themes
inside it -- so all ten go, and none of them goes on its own account.

The manager installs themes but never loads them. That is the host's registry's
job, and it is why installing a theme doesn't add a running plugin — it adds an
entry to the theme switcher.

**Full page:** [a-theme — what it does, what you press, and how it works](../../docs/building/a-theme.md)

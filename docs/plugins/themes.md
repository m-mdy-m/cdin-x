# themes

The ten bundled themes, and the switch that changes between them.

| key | does |
| --- | --- |
| <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>T</kbd> | `core:change-theme` — pick from a searchable list |

| theme | |
| --- | --- |
| `default` | the one a build starts in |
| `catppuccin-mocha` | |
| `dracula` | |
| `github-light` | the light one |
| `gruvbox-dark` | |
| `monokai` | |
| `nord` | |
| `solarized-dark` | |
| `solarized-light` | |
| `tokyo-night` | |

## themes is not a theme

The package is a directory of themes **plus** the thing that switches between
them, so its `kind` is `plugin` and its name does not start with `theme-`.

A `theme` package is a single `<name>/theme.lua`, its own name starts with
`theme-`, and it carries no code. This one is a container, and calling it a theme
would make the schema demand a prefix that says nothing true.

```text
themes/
  themes/default/theme.lua        <- each theme is one directory
  themes/nord/theme.lua
  features/switcher.lua           <- the picker, as a feature
  with/themes.lua                  <- persistence, only while session is on
```

**To add a theme of your own you do not need this package.** A theme is a
directory with a `theme.lua` in it, and cdin's registry reads any root you give
it. See [adding a theme](../building/a-theme.md).

## The switcher is a feature

`switcher` is one feature of this package, and can be switched off on its own:

```lua
return { features = { themes = { switcher = false } } }
```

With it off the ten themes are still registered and still selectable from a
`config.theme` line in your `init.lua` — you just lose the list.

**`config.theme` is a host key.** The host applies it, before packages run and
once more after. So it is written at the top level of `config` and not
namespaced: `config.themes.theme` would be a key nothing reads, and the switcher
would appear to work while changing nothing.

## What makes the choice survive a restart

Nothing in this package does that. It is a **`with` entry** — `with/themes.lua` —
and it exists only while both `themes` and `session` are active:

```lua
-- themes/package.lua
with = {
  workspace = "with/themes.lua",
}
```

The key is a **package name**, not a feature name, which is what makes the rule
checkable: the validator can see that a `with` file reaches into exactly the
package its manifest named and nowhere else. It reaches
`workspace.session.api`, because `session` is a *feature* of `workspace` and a
`with` file is allowed to say so.

So, with the default build:

| | choice persists? |
| --- | --- |
| `themes` on, `workspace`'s `session` on | yes |
| `themes` on, `session` off | no — the change applies, and is gone next start |
| `switcher` off | n/a — you set `config.theme` yourself, and that is read at startup |

That last row is the one worth knowing: **`config.theme` in your `init.lua` does
not need the `with` entry at all.** The entry is only for remembering a choice you
made *interactively*.

See [building a with entry](../building/a-with-entry.md) for the mechanism.

## How it works

**The picker is a `core.command_view`.** The same prompt the palette and the file
finder use, so the keystrokes inside it are the same ones, and none of them are
new bindings.

**Changes go out through a seam, not directly.** `switcher.on_change(fn)` returns
`fn` so the caller can hand the *same value* back to `off_change` — removals
compare by identity, and a function built fresh at removal time matches nothing
and the subscription survives the package being switched off. The `with` entry
subscribes here rather than reaching into the switcher's internals, which is why
those two functions are public rather than a local list.
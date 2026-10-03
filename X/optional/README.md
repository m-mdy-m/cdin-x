# optional

Plugins that aren't a capability anyone depends on, and that nobody is
waiting for. Installed by the user, from the manager, like any other plugin.

| directory | does |
| --- | --- |
| `rtl_toggle/` | switch text direction and Arabic shaping at runtime |
| `theme_switcher/` | pick a theme — `session-theme-switcher` is what remembers it |
| `unicode_inspect/` | show the code points around the caret |

Same rule as [`../core/`](../core): a plugin here may not depend on another X
plugin. Being optional is about whether people want it, not about what it is
allowed to know.

None of these are `essential`. Only `vim`, `manager` and the `default` theme are, and
neither lives here.

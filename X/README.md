# X

Every plugin in the catalog, except the manager.

Installed as `<site>/X/`, and the host puts `<site>/X/?.lua` on `package.path`
*after* its own modules — so a plugin is required by its path from here, and
cannot shadow anything of the editor's.

Five categories, and the category is a rule rather than a label:

| directory | holds | may depend on |
| --- | --- | --- |
| [`core/`](core) | one capability each | the host, and itself |
| [`integration/`](integration) | the wiring between capabilities | two or more other plugins |
| [`optional/`](optional) | genuinely optional plugins | the host, and itself |
| [`syntax/`](syntax) | language definitions | the host |
| [`themes/`](themes) | themes, as `<name>/theme.lua` | the host |

The rule that makes the catalog checkable: a `core/` plugin may not depend on
another X plugin. If two need to know about each other, that knowledge goes in
`integration/`, which declares it in its manifest. `make validate` enforces
this.

`X/manifest.lua` is generated — run `make manifest`. Don't edit it, and don't
require it.

**How to write one of these:** [docs/writing-a-plugin.md](../docs/writing-a-plugin.md).
**Worked examples:** [examples/](../examples).

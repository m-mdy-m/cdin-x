# optional

**Empty.** Kept as a home for a genuinely standalone package, and nothing is in
it.

It used to hold `rtl_toggle`, `theme_switcher` and `unicode_inspect`. All three
are now features of two packages, which is where they belong:

| was | is now |
| --- | --- |
| `rtl_toggle`, `unicode_inspect` | features `rtl` and `unicode` of [`text-tools`](../../packages/system/text-tools) |
| `theme_switcher` | the `switcher` feature of [`themes`](../../packages/system/themes) |

Same rule as [`../core/`](../core), and it is the rule for every directory here: a
package may not depend on another package. Being here would have been about
whether people want it, not about what it is allowed to know \u{2014} which is
exactly why it was the wrong axis. **What a build carries** is `bundles/*.lua`
and nothing else; there is no per-package flag, and `make validate` rejects one
by name.

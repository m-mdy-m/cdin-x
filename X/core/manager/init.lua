-- CDIN-X: the extension manager, bundled into every cdin build.
--
-- essential = true, so a cdin build carries it the way it carries vim. The
-- reasoning is the same and it is not about features: an editor whose only
-- answer to "what is installed, and how do I change that" is a script in
-- another repository is not finished, and the person who notices is always
-- the one who just installed something and cannot see it. Everything
-- optional stays optional — this plugin manages extensions, it is not a
-- prerequisite for any of them.
--
-- The manager's code lives in cdinx/ at the checkout root, and `bundle_with`
-- below is what carries it into a build: scripts/bundle.py copies the listed
-- paths next to the plugin, layout preserved, so `require "cdinx"` resolves
-- from <data>/cdinx/ exactly as it does from a checkout. Declaring it here
-- rather than letting the bundler guess is the point — a bundle that needs
-- files the bundler did not know about is a build whose editor loads and
-- then does nothing.
--
-- Nothing is required at the top level. The catalog reads this file with
-- dofile() to get the manifest, and a top-level require would run the whole
-- manager, panel and all, merely to look this plugin up.
local M = {
  name = "manager",
  version = "0.2.0",
  description = "Browse, search, install and remove extensions from inside the editor",
  author = "cdin Team",
  license = "MIT",
  category = "core",
  type = "plugin",
  essential = true,
  dependencies = {},
  min_cdin_version = "0.5.0",
  tags = { "essential", "manager", "extensions" },
  -- Paths, relative to the cdin-x checkout root, that must travel with this
  -- plugin into a build. Copied verbatim into the destination.
  bundle_with = { "cdinx" },
}

local booted = false

local function join(...)
  local sep  = PATHSEP or package.config:sub(1, 1)
  local out = {}
  for i = 1, select("#", ...) do
    local s = tostring(select(i, ...))
    if i > 1 and #s > 0 and not s:match("[/\\]$") then out[#out + 1] = sep end
    out[#out + 1] = s
  end
  return table.concat(out)
end

function M.init(core, config)
  if booted then return end

  -- Themes first, and this is the same ordering problem the site entry has.
  -- config.theme is applied at style.lua load time, long before any plugin
  -- runs, so a theme that lives in an extension's root has to be registered
  -- before the manager picks anything up or the first frame renders with the
  -- fallback.
  local themes = require("core.themes")

  -- The set a build ships with: vim, the default theme, this manager.
  -- config.bundle_dir comes from the host (config.data_dir) and is nil for
  -- an extension set that is not sitting next to a build.
  if config.bundle_dir then
    themes.add_root(join(config.bundle_dir, "X", "themes"))
  end
  -- An installed cdin-x brings its own catalog and themes with it.
  themes.add_root(join(config.site_dir, "X", "themes"))

  local ok, err = require("cdinx").bootstrap()
  if not ok then
    core.error("cdin-x: %s", tostring(err or "bootstrap failed"))
    return
  end
  booted = true
end

function M.unload()
  -- Nothing to unwind: the manager's registrations belong to the extensions
  -- it loaded, and tearing the manager out from under them would leave their
  -- commands and keymaps live with nothing left to remove them.
  booted = false
end

return M

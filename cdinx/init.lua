-- CDIN-X runtime bootstrap.
--
-- Required as `require "cdinx"`, from the entry plugin at
-- plugins/cdin-x/init.lua. The host never names this module: cdin only
-- knows that it loads a bundled plugin, a site plugin, and whatever a
-- plugin's init() does. Everything below is reached from that one call.
local Host = require "cdinx.host"
local config = require "cdinx.config"
local cdin_x = {}
local booted = false

local function count(t)
  local n = 0
  for _ in pairs(t or {}) do n = n + 1 end
  return n
end

--- Where themes live, and why the kernel is the thing that knows.
---
--- The host adds `<data>/themes` itself, so a build's themes are already found
--- and registering that root here would list every one of them twice in the
--- picker. What the host cannot know about is a *site* install, which puts
--- themes under the site directory. Both roots the site may hold are added:
--- `X/themes` where they are today, `packages/themes` where a package tree puts
--- them. A root that does not exist costs nothing — the theme registry ignores
--- it, which is why a build has always registered one that was absent.
local function register_theme_roots()
  local ok, themes = pcall(require, "core.themes")
  if not ok then return end

  local sep = Host.sep or package.config:sub(1, 1)
  local function join(...)
    local out = {}
    for i = 1, select("#", ...) do
      local part = tostring(select(i, ...))
      if i > 1 and part ~= "" and not part:match("[/\\]$") then out[#out + 1] = sep end
      out[#out + 1] = part
    end
    return table.concat(out)
  end

  themes.add_root(join(config.site_dir, "X", "themes"))
  themes.add_root(join(config.site_dir, "packages", "themes"))
end

function cdin_x.bootstrap()
  if booted then return true end
  booted = true

  -- Before the manager picks anything up: config.theme is applied at style.lua
  -- load time, long before a plugin runs, so a theme that lives under the site
  -- directory has to be registered before the first frame renders or the editor
  -- draws with the fallback and then changes colour underneath the user.
  register_theme_roots()

  local Manager = require "cdinx.manager"
  local ok, err = Manager.bootstrap()
  if not ok then
    booted = false
    return false, err
  end

  local Command = require "cdinx.command"
  Command.register()

  require("cdinx.panel").register()

  Host.core.cdinx = cdin_x
  Host.core.log("cdin-x bootstrapped")
  Host.core.log("  built-in: %d", count(Manager.list_builtin()))
  Host.core.log("  installed: %d", count(Manager.list_local()))
  return true
end

function cdin_x.install(name)
  return require("cdinx.manager").install(name)
end

function cdin_x.install_local(path)
  return require("cdinx.manager").install_local(path)
end

function cdin_x.uninstall(name)
  return require("cdinx.manager").uninstall(name)
end

function cdin_x.enable(name)
  return require("cdinx.manager").enable(name)
end

function cdin_x.disable(name)
  return require("cdinx.manager").disable(name)
end

function cdin_x.refresh()
  return require("cdinx.manager").refresh_registry()
end

function cdin_x.update(name)
  return require("cdinx.manager").update(name)
end

function cdin_x.clean(dry_run)
  return require("cdinx.manager").clean(dry_run)
end

function cdin_x.list()
  return require("cdinx.manager").list()
end

function cdin_x.search(query)
  return require("cdinx.manager").search(query)
end

function cdin_x.get(name)
  return require("cdinx.manager").get(name)
end

function cdin_x.open_readme(name)
  return require("cdinx.manager").open_readme(name)
end

return cdin_x

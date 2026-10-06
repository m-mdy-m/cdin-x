-- The one place that reads a cdin global or a host module.
--
-- Everything else in the kernel goes through here, so there is one list of what
-- cdin-x depends on from cdin. A host module that moves, or a global the host
-- stops defining, is a change to this file and to nothing else.
local core   = require "core"
local fs     = require "core.fs"
local config = require "cdinx.config"

local Host = {
  core = core,
  fs = fs,
  config = config,
}

--- The host's path separator, from the global it defines.
--- Falls back to Lua's own, which is what every module did on its own before.
Host.sep = rawget(_G, "PATHSEP") or package.config:sub(1, 1)

--- Whether paths are written with Windows separators.
Host.is_windows = Host.sep == "\\"

--- The host's version, which is what `min_cdin_version` is compared against.
--- Captured once at load: it cannot change while the editor runs, and reading a
--- global on every comparison would make a package's compatibility check depend
--- on where in the file it happens to be.
---
--- The host pushes `VERSION` from C (`lua_setup_globals`), and it is that same
--- value `empty_view.lua` shows in its logo -- so a build that renders "v0.6.1" and
--- a package that reads 0.6.1 here agree by construction rather than by two
--- lookups happening to match.
---
--- `CDIN_VERSION` is *not* a global. `config.c` uses that name as a C macro
--- (`-DCDIN_VERSION=...`) and `empty_view.lua` looks for it as a Lua global that
--- nothing ever sets, so the fallback there is always "dev". Read from both so a
--- host that starts setting one is picked up without a change here.
Host.version = rawget(_G, "VERSION") or rawget(_G, "CDIN_VERSION")

--- The host's display scale, for anything that sizes itself in pixels.
Host.scale = rawget(_G, "SCALE") or 1

--- The host's process and clock module, for the rare caller that needs
--- something this adapter does not wrap.
Host.system = rawget(_G, "system")

--- The host's drawing module.
Host.renderer = rawget(_G, "renderer")

--- @param message string
--- @param ... any  printf arguments, as core.log takes them
function Host.log(message, ...)
  core.log(message, ...)
end

--- @param message string
--- @param ... any  printf arguments, as core.error takes them
function Host.error(message, ...)
  core.error(message, ...)
end

--- Seconds since an unspecified epoch, from the host's clock.
--- @return number
function Host.time()
  return system.get_time()
end

--- Runs a shell command without waiting for it.
--- @param command string
function Host.exec(command)
  system.exec(command)
end

--- Seconds to yield for; the host's own idle slice.
function Host.sleep(seconds)
  system.sleep(seconds)
end

-- Removed: `Host.join`. `Util.join` does the same job -- it inserts `Host.sep`
-- between segments -- and it is the one with callers: 23 of them. Two functions for
-- one operation, where the unused one is also subtly worse (it stringifies its
-- arguments, so a number or a nil segment becomes text instead of failing), is a
-- duplicate that survives because removing the *unused* copy reads as tidying rather
-- than as a decision.
--
-- This file is the single reader of the host's globals and its modules. Joining
-- path segments is not reading the host, it is string handling, so it belongs in
-- util -- and now it is only there.

return Host
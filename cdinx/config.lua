-- CDIN-X runtime defaults.
local config = require "core.config"
local sep = PATHSEP or package.config:sub(1, 1)
local is_win = sep == "\\"

local function env(name)
  local v = os.getenv(name)
  return v and v ~= "" and v or nil
end

local home
local config_home
local data_home

if is_win then
  home = env("USERPROFILE") or env("HOME") or "."
  config_home = env("APPDATA") or (home .. "\\AppData\\Roaming")
  data_home = env("LOCALAPPDATA") or env("APPDATA") or (home .. "\\AppData\\Local")
else
  home = env("HOME") or "."
  config_home = env("XDG_CONFIG_HOME") or (home .. "/.config")
  data_home = env("XDG_DATA_HOME") or (home .. "/.local/share")
end

local base_config = config_home .. sep .. "cdin"
local base_data   = data_home .. sep .. "cdin"
config.site_dir       = config.site_dir or (env("CDIN_SITE_DIR") or (base_data .. sep .. "site"))

config.user_root      = config.user_root or base_config
config.user_dir       = config.user_dir or (base_config .. sep .. "user")
config.extension_dir  = config.extension_dir or (base_data .. sep .. "extensions")
config.registry_dir   = config.registry_dir or (env("CDIN_X_REGISTRY")
                                        or (base_data .. sep .. "registry" .. sep .. "cdin-x"))
config.state_file     = config.state_file or (base_data .. sep .. "extensions.lua")
config.registry_url   = config.registry_url or "https://github.com/m-mdy-m/cdin-x.git"

-- config.fonts_dir is deliberately NOT set here. The fonts are part of the
-- mandatory bundle and the host already points at them; an extension that
-- needed a different font would shadow the editor's own text rendering.

return config
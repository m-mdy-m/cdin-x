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

config.site_dir       = config.site_path()

config.bundle_dir     = config.bundle_dir or config.data_dir

config.user_root      = config.user_root or base_config
config.user_dir       = config.user_dir or (base_config .. sep .. "user")

config.legacy_extension_dir = config.extension_dir and nil
                            or (base_data .. sep .. "extensions")
config.extension_dir  = config.extension_dir
                     or (base_data .. sep .. "extensions" .. sep .. "X")
config.registry_dir   = config.registry_dir or (env("CDIN_X_REGISTRY")
                                        or (base_data .. sep .. "registry" .. sep .. "cdin-x"))
config.state_file     = config.state_file or (base_data .. sep .. "extensions.lua")
config.registry_url   = config.registry_url or "https://github.com/m-mdy-m/cdin-x.git"

local function raw_url_from(url)
  local owner, repo = tostring(url):match("github%.com[/:]([^/]+)/([^/]+)")
  if not owner then return nil end
  repo = repo:gsub("%.git$", "")
  return "https://raw.githubusercontent.com/" .. owner .. "/" .. repo
    .. "/" .. (env("CDIN_X_BRANCH") or "main")
end

config.registry_raw_url = config.registry_raw_url
  or raw_url_from(config.registry_url)
  or "https://raw.githubusercontent.com/m-mdy-m/cdin-x/main"

return config
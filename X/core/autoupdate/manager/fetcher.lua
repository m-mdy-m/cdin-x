local Utils = require "X.core.autoupdate.manager.utils"
local M = {}

function M.latest_tag()
  local url = "https://api.github.com/repos/m-mdy-m/cdin/releases/latest"
  local raw
  if Utils.IS_WIN then
    local cmd = string.format(
      "powershell -NoProfile -NonInteractive -Command " ..
      "\"(Invoke-WebRequest -Uri '%s' -UseBasicParsing).Content\"", url)
    local ok, fp = pcall(io.popen, cmd)
    if ok and fp then raw = fp:read("*a"); fp:close() end
  else
    local cmd = string.format(
      "curl -sf --max-time 10 -H 'Accept: application/vnd.github.v3+json' " ..
      "-H 'User-Agent: cdin-autoupdate' '%s'", url)
    local ok, fp = pcall(io.popen, cmd)
    if ok and fp then raw = fp:read("*a"); fp:close() end
  end
  if not raw or raw == "" then return nil end
  return raw:match('"tag_name"%s*:%s*"v?([^"]+)"')
end

return M

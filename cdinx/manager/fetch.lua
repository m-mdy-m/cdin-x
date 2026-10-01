-- Fetching from the catalog: the one thing the manager needs from the network.
--
-- There is NO git here, and nothing is cloned. The catalog is the cdin-x
-- repository, but the editor only ever downloads individual files from it,
-- over plain HTTPS, from raw.githubusercontent.com:
--
--   "what can I install?"   one file: X/manifest.lua (~16 KiB). It lists every
--                           extension with its category, version, description
--                           and the exact files it is made of. Searching the
--                           panel is a lookup in this file; it installs
--                           nothing and downloads nothing else.
--   "give me this one"      exactly the files that extension's manifest entry
--                           lists, and no others. Installing one theme
--                           downloads that theme's theme.lua.
--
-- Two ways in:
--
--   Fetch.start / Fetch.poll   non-blocking: the downloader runs detached and
--                              writes a marker file when it ends; the caller
--                              polls from a thread. The panel uses this for
--                              the catalog, so the editor never freezes.
--   Fetch.sync                 the same, waited for.
--   Fetch.download             one extension's files into a staging directory,
--                              waited for (the install that follows needs them).
--
-- Downloader: curl (Windows 10+, macOS and most Linux ship it; Git for
-- Windows bundles it), else wget, else PowerShell on Windows.
--
-- Files land in a staging directory first and are only moved into place once
-- the whole download succeeded, so a half-downloaded extension or catalog is
-- never visible to the scanner.
local fs = require "core.fs"

local Fetch = {}

local IS_WIN  = (PATHSEP or package.config:sub(1, 1)) == "\\"
local SEP     = IS_WIN and "\\" or "/"
local TIMEOUT = 120   -- seconds before a download is declared dead

-- The one file the catalog is read from.
local CATALOG_FILE = "X/manifest.lua"

local function native(path)
  path = tostring(path)
  if IS_WIN then path = path:gsub("/", "\\") end
  return path
end

local function strip_trailing(path)
  return (native(path):gsub("[/\\]+$", ""))
end

-- Quoting for a local path (separators normalised).
local function quote(s)
  s = native(s)
  if IS_WIN then return '"' .. s .. '"' end
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

-- Quoting for a URL: no separator rewriting, or https:// would be mangled.
-- URLs are built from validated pieces (see safe_relpath), so no quote
-- characters can be in them.
local function quote_url(u)
  if IS_WIN then return '"' .. u .. '"' end
  return "'" .. u .. "'"
end

local function read_all(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local text = f:read("*a")
  f:close()
  return text
end

local function write_all(path, text)
  local f = io.open(path, "wb")
  if not f then return false end
  f:write(text)
  f:close()
  return true
end

local function last_line(path)
  local text = read_all(path)
  if not text then return nil end
  local last
  for line in text:gmatch("[^\r\n]+") do last = line end
  return last
end

local function remove(path)
  if fs.exists(path) then fs.rm(path) end
end

-- mkdir -p. fs.mkdir is only relied on for one level.
local function mkdir_p(path)
  path = native(path)
  local prefix = ""
  for part, sep in path:gmatch("([^/\\]*)([/\\]?)") do
    prefix = prefix .. part .. sep
    if part ~= "" and not part:match("^%a:$") and not fs.is_dir(prefix) then
      fs.mkdir(prefix)
    end
  end
  return fs.is_dir(path)
end

Fetch.mkdir_p = mkdir_p

local function capture(cmd)
  if system and system.popen then
    return system.popen(cmd)
  end
  local ok, fp = pcall(io.popen, cmd)
  if not ok or not fp then return nil end
  local out = fp:read("*a")
  fp:close()
  return out
end

-- ── paths from the catalog are untrusted ─────────────────────────────────

-- A file path out of the manifest ("X/themes/nord/theme.lua") becomes both a
-- URL and a path on this machine, so it is held to a boring alphabet and may
-- not climb out of where it is going.
local function safe_relpath(rel)
  if type(rel) ~= "string" or rel == "" then return false end
  if not rel:match("^[%w%-%._/]+$") then return false end
  if rel:sub(1, 1) == "/" or rel:find("//", 1, true) then return false end
  for part in rel:gmatch("[^/]+") do
    if part == ".." or part == "." then return false end
  end
  return true
end

-- ── finding a downloader ─────────────────────────────────────────────────

local cached_dl

local function probe(cmd)
  if not IS_WIN then cmd = cmd .. " 2>/dev/null" end
  return capture(cmd)
end

-- Returns { kind = "curl"|"wget"|"powershell", exe = <command> } or nil.
function Fetch.find_downloader()
  if cached_dl ~= nil then return cached_dl or nil end

  local curls = IS_WIN
    and { "curl", (os.getenv("SystemRoot") or "C:\\Windows") .. "\\System32\\curl.exe" }
    or  { "curl", "/usr/bin/curl", "/usr/local/bin/curl", "/opt/homebrew/bin/curl" }

  for _, candidate in ipairs(curls) do
    local usable, exe = true, candidate
    if candidate ~= "curl" then
      usable = fs.is_file(candidate)
      exe = quote(candidate)
    end
    if usable then
      local out = probe(exe .. " --version")
      if out and out:match("^curl") then
        cached_dl = { kind = "curl", exe = exe }
        return cached_dl
      end
    end
  end

  if not IS_WIN then
    local out = probe("wget --version")
    if out and out:match("Wget") then
      cached_dl = { kind = "wget", exe = "wget" }
      return cached_dl
    end
  else
    -- Always present on Windows 7+; no reliable cheap probe through cmd.
    cached_dl = { kind = "powershell", exe = "powershell" }
    return cached_dl
  end

  cached_dl = false
  return nil
end

-- ── the job ──────────────────────────────────────────────────────────────

-- items = { { url = ..., dest = ... }, ... }. Returns the shell command that
-- fetches them all, or nil plus a reason. `script` is where a PowerShell
-- script may be written.
local function build_command(dl, items, script)
  if dl.kind == "curl" then
    local parts = { dl.exe, "-fsSL", "--fail-early", "--retry", "2",
      "--connect-timeout", "15", "--max-time", tostring(TIMEOUT),
      "--create-dirs" }
    for _, item in ipairs(items) do
      parts[#parts + 1] = "-o " .. quote(item.dest) .. " " .. quote_url(item.url)
    end
    return table.concat(parts, " ")
  end

  if dl.kind == "wget" then
    local parts = {}
    for _, item in ipairs(items) do
      parts[#parts + 1] = "wget -q -O " .. quote(item.dest) .. " " .. quote_url(item.url)
    end
    return table.concat(parts, " && ")
  end

  -- PowerShell: a script file, so no quoting has to survive cmd.exe.
  local function ps(s) return "'" .. native(s):gsub("'", "''") .. "'" end
  local lines = {
    "$ErrorActionPreference='Stop'",
    "$ProgressPreference='SilentlyContinue'",
    "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}",
  }
  for _, item in ipairs(items) do
    lines[#lines + 1] = "Invoke-WebRequest -UseBasicParsing -Uri '" .. item.url
      .. "' -OutFile " .. ps(item.dest)
  end
  if not write_all(script, table.concat(lines, "\r\n") .. "\r\n") then
    return nil, "could not write " .. script
  end
  return "powershell -NoProfile -ExecutionPolicy Bypass -File " .. quote(script)
end

-- Wraps `work` so it leaves `done` behind ("ok"/"fail") and its output in
-- `log`, and runs it detached.
local function launch(work, done, log)
  local shell
  if IS_WIN then
    -- cmd strips the outer pair of quotes, which is what lets the inner ones
    -- (paths with spaces) survive.
    shell = 'cmd.exe /C "' .. work .. " > " .. quote(log) .. " 2>&1"
      .. " && echo ok> " .. quote(done)
      .. " || echo fail> " .. quote(done) .. '"'
  else
    shell = work .. " > " .. quote(log) .. " 2>&1"
      .. " && echo ok > " .. quote(done)
      .. " || echo fail > " .. quote(done)
  end
  system.exec(shell)
end

local function new_job(base, items, script)
  local dl = Fetch.find_downloader()
  if not dl then
    return nil, "no downloader found; install curl (or wget) and make sure it is on PATH"
  end

  local done, log = base .. ".done", base .. ".log"
  local made, merr = mkdir_p(fs.dirname(base))
  if not made then return nil, merr or ("cannot create " .. fs.dirname(base)) end
  remove(done)
  remove(log)

  for _, item in ipairs(items) do
    mkdir_p(fs.dirname(item.dest))
    remove(item.dest)
  end

  local work, werr = build_command(dl, items, script)
  if not work then return nil, werr end

  launch(work, done, log)
  return { done = done, log = log, items = items, started = system.get_time() }
end

-- nil while it runs; true when it succeeded; false plus a reason when not.
local function poll_job(job)
  local marker = read_all(job.done)
  if not marker then
    if system.get_time() - job.started > TIMEOUT + 10 then
      return false, "timed out after " .. TIMEOUT .. "s"
    end
    return nil
  end
  if not marker:match("^ok") then
    return false, last_line(job.log) or "download failed"
  end
  for _, item in ipairs(job.items) do
    if not fs.is_file(item.dest) then
      return false, "download did not produce " .. tostring(item.dest)
    end
  end
  return true
end

local function finish_job(job)
  remove(job.done)
  remove(job.log)
end

-- ── the catalog ──────────────────────────────────────────────────────────

local function catalog_paths(registry_dir)
  local dir    = strip_trailing(registry_dir)
  local target = dir .. SEP .. "X" .. SEP .. "manifest.lua"
  return dir, target, target .. ".part"
end

-- Starts downloading the catalog index into `registry_dir`/X/manifest.lua.
-- `base_url` is the raw root of the repository
-- ("https://raw.githubusercontent.com/<owner>/<repo>/<branch>"). Returns a
-- job to poll, or nil plus the reason it could not even start.
function Fetch.start(registry_dir, base_url)
  if type(base_url) ~= "string" or not base_url:match("^https://[%w%-%._/]+$") then
    return nil, "config.registry_raw_url is not a usable https URL: " .. tostring(base_url)
  end
  local dir, target, part = catalog_paths(registry_dir)

  local job, err = new_job(dir .. ".catalog", {
    { url = base_url:gsub("/+$", "") .. "/" .. CATALOG_FILE, dest = part },
  }, dir .. ".catalog.ps1")
  if not job then return nil, err end

  job.target = target
  job.part   = part
  job.script = dir .. ".catalog.ps1"
  return job
end

function Fetch.poll(job)
  local ok, err = poll_job(job)
  if ok == nil or ok == false then return ok, err end

  -- It must be a catalog before it replaces one.
  local loaded, data = pcall(dofile, job.part)
  if not loaded or type(data) ~= "table" or type(data.plugins) ~= "table" then
    remove(job.part)
    finish_job(job)
    return false, "the downloaded file is not a cdin-x catalog"
  end

  remove(job.target)
  local moved, merr = fs.move(job.part, job.target)
  if not moved then
    finish_job(job)
    return false, merr or "could not store the catalog"
  end

  finish_job(job)
  if job.script then remove(job.script) end
  return true
end

-- The same, waited for. Blocks the editor, so it is for callers that have no
-- other choice; the panel does not use it.
function Fetch.sync(registry_dir, base_url)
  local job, err = Fetch.start(registry_dir, base_url)
  if not job then return false, err end
  while true do
    local ok, perr = Fetch.poll(job)
    if ok ~= nil then return ok, perr end
    system.sleep(0.05)
  end
end

-- ── one extension ────────────────────────────────────────────────────────

-- Downloads exactly the files in `files` (as listed by the catalog:
-- "X/themes/nord/theme.lua") into a staging directory, keeping their layout
-- minus the leading "X/". Returns the staging root, or false plus a reason.
--
-- Blocking on purpose: the user asked for this one extension, and the copy
-- that follows needs the files to be there. It is a few kilobytes.
function Fetch.download(registry_dir, base_url, name, files)
  if type(files) ~= "table" or #files == 0 then
    return false, "the catalog lists no files for " .. tostring(name)
  end
  if type(name) ~= "string" or not name:match("^[%w%-%._]+$") then
    return false, "unusable extension name: " .. tostring(name)
  end
  if type(base_url) ~= "string" or not base_url:match("^https://[%w%-%._/]+$") then
    return false, "config.registry_raw_url is not a usable https URL"
  end
  base_url = base_url:gsub("/+$", "")

  local dir     = strip_trailing(registry_dir)
  local staging = dir .. SEP .. "staging" .. SEP .. name
  remove(staging)

  local items = {}
  for _, rel in ipairs(files) do
    if not safe_relpath(rel) or rel:sub(1, 2) ~= "X/" then
      return false, "the catalog lists an unsafe path for " .. name .. ": " .. tostring(rel)
    end
    items[#items + 1] = {
      url  = base_url .. "/" .. rel,
      dest = staging .. SEP .. native(rel:sub(3)),
    }
  end

  local job, err = new_job(dir .. ".dl", items, dir .. ".dl.ps1")
  if not job then return false, err end

  while true do
    local ok, perr = poll_job(job)
    if ok ~= nil then
      finish_job(job)
      remove(dir .. ".dl.ps1")
      if not ok then
        remove(staging)
        return false, "could not download " .. name .. ": " .. tostring(perr)
      end
      return staging
    end
    system.sleep(0.05)
  end
end

-- Drops a staging directory once its contents have been copied.
function Fetch.discard(path)
  if path then remove(path) end
end

Fetch.CATALOG_FILE = CATALOG_FILE

return Fetch

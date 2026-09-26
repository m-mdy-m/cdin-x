local M={}
function M.exists(p) local f=io.open(p,"rb");if f then f:close();return true end;return false end
function M.list_dir(p) local r={} local h=io.popen('ls -1 "'..p..'" 2>/dev/null') if h then for l in h:lines() do local f=p.."/"..l local a=io.popen('stat -c "%F" "'..f..'" 2>/dev/null'):read("*a"):gsub("%s+","") table.insert(r,{name=l,type(a=="directory"and"dir"or"file")}) end h:close() end return r end
function M.dirname(p) return p:match("^(.*)[/\\][^/\\]+$") end
function M.basename(p) return p:match("([^/\\]+)[/\\]?$") end
function M.manifest_paths() return {} end
function M.read_manifest(p) local ok,m=pcall(dofile,p);if ok and type(m)=="table" then return m end;return nil end
return M

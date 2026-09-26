local M={}
local function sp() return os.getenv("HOME").."/.config/cdin/session" end
function M.read() local p=sp();local f=io.open(p,"r");if not f then return{}end local c=f:read("*a");f:close();local ok,d=pcall(function() return loadstring(c)() end);if ok and type(d)=="table" then return d end;return{} end
function M.write(d) local p=sp();local f=io.open(p,"w");if not f then return end;f:write("return "..tostring(d));f:close() end
return M

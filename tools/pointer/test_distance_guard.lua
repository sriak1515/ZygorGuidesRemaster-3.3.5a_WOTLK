-- Usage: lua tools/pointer/test_distance_guard.lua [addon directory]
local root = arg[1] or "ZygorGuidesViewerRM"
local file = assert(io.open(root.."/Pointer.lua", "rb"))
local source = file:read("*a")
file:close()
local first = assert(source:find("function Pointer:GetDistTxt(dist, waypoint)", 1, true))
local last = assert(source:find("function Pointer:GetETATxt", first, true))
Pointer = {GetFarText = function() return "far" end}
local FormatDistance = function(n) return tostring(n).." yd" end
assert((loadstring or load)("local FormatDistance = ...\n"..source:sub(first,last-1)))(FormatDistance)
assert(Pointer:GetDistTxt(1800000, {}) == nil)
assert(Pointer:GetDistTxt(1000, {}) == "1000 yd")
assert(Pointer:GetDistTxt(9999999, {}) == "far")
print("Distance display guard passed")

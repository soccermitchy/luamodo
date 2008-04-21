Extension = {}
Extension_mt = {}
Extension_mt.__index = Extension
Extension_mt.__type = "Extension"
TableTypes["Extension"] = true
function Extension:New(id)
	local mt = setmetatable({Hooks = {},Cmds = {},CTCP = {},ID = id,Bots = {}},Extension_mt)
	Extensions[id] = mt
	return mt
end
function Extension:Think()
end
function Extension:Setup()
	print("you probably should have overridden the SetupBot function")
end
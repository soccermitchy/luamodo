Bots = {}
Connections = {}
Sockets = {}
Prefix = {}
DispQueue = {}
Extensions = {}
Prefix["~"] = "a"
Prefix["@"] = "o"
Prefix["%"] = "h"
Prefix["+"] = "v"
Prefix["a"] = "~"
Prefix["o"] = "@"
Prefix["h"] = "%"
Prefix["v"] = "+"
ControlCodes = {}
ControlCodes.Colour = "\3"
ControlCodes.Bold = "\2"
ControlCodes.Underline = "\31"
ControlCodes.Halt = "\15"
function ParseModes(modes,args)
	args = explode(" ",args)
	modes = explode("",modes)
	tab = {}
	status = "+"
	for k,v in pairs(modes) do
		if (v == "+") or (v == "-") then
			status = v
		else
			ind = table.getn(tab)+1
			tab[ind] = {}
			tab[ind].status = status
			tab[ind].mode = v
			tab[ind].arg = ""
		end
	end
	difference = #tab - #args
	for i = 1, difference do --pad the table
		table.insert(args,1,"")
	end
	for i = 1, #tab do
		tab[i].arg = args[i]
	end
	return tab
end
function Split(text)
	Nick = string.sub(text,1,string.find(text,"!")-1)
	Ident = string.sub(text,string.find(text,"!")+1,string.find(text,"@")-1)
	Host = string.sub(text,string.find(text,"@")+1)
	return Nick,Ident,Host
end
function SetObject(socket,object)
	Sockets[tostring(socket)] = object
end
function GetObject(socket)
	return Sockets[tostring(socket)]
end
function BuildReadTable()
	local temptable = {}
	for k,v in pairs(Connections) do
		--print(v.ID)
		table.insert(temptable,v.Socket)
	end
	return temptable
end
function MainLoop()
	while true do
		for k,v in pairs(Bots) do
			v:Think()
		end
		for k,v in pairs(Extensions) do
			v:Think()
		end
		local readtable = BuildReadTable()
		--local writetable = BuildWriteTable()
		local Read,_,Error = socket.select(readtable,{},1)
		if (Error ~= nil) and (Error ~= "timeout") then
			print(error)
		end
		for i = 1, table.getn(Read) do
			local Object = GetObject(Read[i])
			Object:Read()
		end
		--[[for i = 1, table.getn(Write) do
			local Object = GetObject(Write[i])
			Object:Write()
		end]]
	end
end
function GetPrefix(nick)
	prefix = string.sub(nick,1,1)
	if (Prefix[prefix]) then
		return prefix,string.sub(nick,2)
	else
		return nil,nick
	end
end
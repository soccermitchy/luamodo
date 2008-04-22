Bot = {}
Bot.Event = {}
Bot_mt = {}
Bot_mt.__index = Bot
Bot_mt.__type = "Bot"
TableTypes["Bot"] = true
--- Creates and returns a new Bot object.
-- Inserts the bot in the Bots table indexed by ID
-- @param ID a string used for the bots index in various tables as well as it's display name for console output
-- @param posnames a table of possible nicks for IRC connections to use
-- @return the newly created bot
-- @usage NewBot = Bot:New("Display Name",{"DefaultNick","AltNick1","AltNick2"})
function Bot:New(ID,posnames)
	local mt = setmetatable({Extensions = {}, Timers = {}, CmdList = {}, CTCPList = {}, HookList = {}, ID = ID, Connections = {}, Settings = {Names = posnames}},Bot_mt)
	Bots[mt.ID] = mt
	return mt
end
--- Loads an extension into a bot.
-- Adds the extensions list of hooks, commands, and CTCP responses to the bot.
-- Then it registers the bot with the extension
-- @param extension the extension object to load
-- @usage NewBot:LoadExtension(somextension)
function Bot:LoadExtension(extension)
	for k,v in pairs(extension.Hooks) do
		self:AddHook(v.Event,v.Name,v.Func)
	end
	for k,v in pairs(extension.Cmds) do
		self:AddCmd(v.Cmd,v.Func)
	end
	for k,v in pairs(extension.CTCP) do
		self:AddCTCP(v.Cmd,v.Func)
	end
	self.Extensions[extension.ID] = extension
	extension:Setup(self)
end
---  Performs the bots timers, then calls :Think() on each connection that belongs to the bot.
-- <br>
-- <i>Note</i>: You do not need to call this manually as the MainLoop function takes care of it.
-- @see Bot:New
-- @usage NewBot:Think()
function Bot:Think()
	self:DoTimers()
	for k,v in pairs(self.Connections) do
		v:Think()
	end
end
--- Adds, modifies, removes, or gets info about a timer.
-- @param name the name of the timer
-- @param delay how long to wait before running the timer, specify "off" to remove the timer
-- @param reps how many times to run the timer (pass 0 for a never-ending timer)
-- @param func the function to run
-- @param args a table of arguments to pass to the function
-- @usage NewBot:Timer("test", 1, 1, print, {"a", "b"}) creates a timer that runs once after one second and prints the strings "a" and "b"
-- @usage NewBot:Timer("test") gets information about the timer
-- @usage NewBot:Timer("test",nil,0) sets the timer to run forever <i>Note</i>: pass nil/omit parameters that you dont want to change
-- @usage NewBot:Timer("test", "off") removes the timer
function Bot:Timer(name,delay,reps,func,args)
	if (reps == 0) then
		reps = -1
	end
	if (delay == "off") then
		self.Timers[name] = nil
		return
	end
	if (name == nil) then
		return false, "name expected for first parameter, got nil"
	end
	if (type(name) ~= "string") and (type(name) ~= "number") then
		return false, "String or number expected for timer name, got ".. type(name)
	end
	if (delay == nil) and (reps == nil) and (func == nil) and (args == nil) then
		if (self.Timers[name]) then
			local ttable = self.Timers[name]
			return ttable
		else
			return false
		end
	end
	if (self.Timers[name]) then
		local ttable = {}
		ttable.delay = delay
		ttable.reps = reps
		ttable.func = func
		ttable.args = args
		ttable.starttime = os.time()
		self.Timers[name] = Merge(self.Timers[name],ttable)
		return self.Timers[name]
	else
		self.Timers[name] = {}
		self.Timers[name].delay = delay
		self.Timers[name].reps = reps
		self.Timers[name].func = func
		self.Timers[name].args = args
		self.Timers[name].starttime = os.time()
		return self.Timers[name]
	end
end
function Bot:DoTimers()
	local Timers = self.Timers
	for k,v in pairs(Timers) do
		difference = os.time() - Timers[k].starttime
		if (difference >= Timers[k].delay) then
			if (Timers[k].reps ~= -1) then
				Timers[k].reps = Timers[k].reps - 1
				func = Timers[k].func
				Timers[k].func(unpack(Timers[k].args))
				if (Timers[k]) then -- make sure the function we just called didn't remove the timer to avoid some nasty errors
					Timers[k].starttime = os.time()
					if (Timers[k].reps == 0) then
						Timers[k] = nil
					end
				end
            else
				Timers[k].func(unpack(Timers[k].args))
				if (Timers[k]) then
                    Timers[k].starttime = os.time()
                end
            end
        end
    end
end
function Bot:Connect(Server,Port,Channels,AuthCmd)
	connection = Connection:New()
	connection.Settings.AltNames = self.Settings.Names
	connection.Settings.Name = self.Settings.Names[1]
	connection.Settings.AuthCmd = AuthCmd or ""
	connection.Settings.ChannelQueue = Channels or {}
	connection.Server = Server
	connection.Port = Port
	connection.Bot = self
	self.Connections[tostring(connection)] = connection
	connection:Connect()
end
function Bot:ConnectionFailure(Connection)
	print(self.ID ..": Unable to connect to ".. Connection.Server .." on port ".. Connection.Port)
end
function Bot:ConnectionSuccess(Connection)
	print(self.ID ..": Successfully connected to ".. Connection.Server .." on port ".. Connection.Port)
end
function Bot:DoHook(event,argtable)
	if (self.HookList[event]) then
		for k,v in pairs(self.HookList[event]) do
			v(argtable)
		end
	end
end
function Bot:AddHook(event,name,func)
	ftype = type(func)
	if (ftype == "function") then
		func = TableFunc(func)
		ftype = "TableFunc"
	end
	if (ftype == "TableFunc") then
		self.HookList[event] = self.HookList[event] or {}
		self.HookList[event][name] = func
		return func
	end
end
function Bot:AddCmd(cmd,func)
	local cmd = string.upper(cmd)
	ftype = type(func)
	if (ftype == "function") then
		func = TableFunc(func)
		ftype = "TableFunc"
	end
	if (ftype == "TableFunc") then
		self.CmdList[cmd] = func
		return func
	end
end
function Bot:DoCmd(cmd,argtable)
	local cmd = string.upper(cmd)
	if (self.CmdList[cmd]) then
		return self.CmdList[cmd](argtable) or false
	end
	return false
end
function Bot:AddCTCP(cmd,func)
	local cmd = string.upper(cmd)
	ftype = type(func)
	if (ftype == "function") then
		func = TableFunc(func)
		ftype = "TableFunc"
	end
	if (ftype == "TableFunc") then
		self.CTCPList[cmd] = func
		return func
	end
end
function Bot:DoCTCP(cmd,argtable)
	local cmd = string.upper(cmd)
	if (self.CTCPList[cmd]) then
		return self.CTCPList[cmd](argtable) or false
	end
	return false
end
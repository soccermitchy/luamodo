Connection = {}
Connection.Event = {}
Connection.Format = {}
Connection.LastDisplay = nil
Connection_mt = {}
Connection_mt.__index = Connection
Connection_mt.__type = "Connection"
TableTypes["Connection"] = true
DISCONNECTED = 0
CONNECTING = 1
CONNECTED = 2
RETRY = 3
function Connection:New()
	return setmetatable({Retries = 0, Server = "", Port = 0, ShouldReconnect = true, ConnectionStatus = DISCONNECTED, Timers = {}, Bot = nil, Settings = {MaxRetries = 5, Timeout = 420, ChannelQueue = {}, AltNames = {}, Name = "", NameIndex = 1, AuthCmd = "", RetryDelay = 5}},Connection_mt)
end
function Connection:Think()
	self:DoTimers()
end
function Connection:Display(str)
	if (Connection.LastDisplay ~= self) then
		Connection.LastDisplay = self
		print("[Bot: " .. self.Bot.ID .."][Connection: ".. self.Server .."(".. self.Settings.Name ..")]")
	end
	print("\t".. str)
end
function Connection:Nick(nick)
	if self.ConnectionStatus ~= DISCONNECTED and self.ConnectionStatus ~= RETRY then
		self:Raw("NICK ".. nick .."\r\n")
	end
end
function Connection:Msg(to,message)
	self:Raw("PRIVMSG ".. to .." :".. message .."\r\n")
end
function Connection:Join(channel,password)
	self:Raw("JOIN ".. channel .." ".. (password or "") .."\r\n")
end
function Connection:CTCP(to,message)
	self:Msg(to,string.char(1) .. message .. string.char(1))
end
function Connection:Raw(message)
	--table.insert(self.MessageQueue,message)
	self.Socket:send(message)
end
function Connection:JoinChannels()
	for i = 1, #self.Settings.ChannelQueue do
		self:Join(self.Settings.ChannelQueue[i].channel,self.Settings.ChannelQueue[i].password)
	end
end
function Connection:Parse(str)
	local from, event, extra = string.match(str,"^%:?(%S+)%s(%S+)%s?(.*)")
	self:Timer("timeout",self.Settings.Timeout,1,self.Timeout,{self})
	if (from == "PING") then
		self:Raw("PONG ".. event .."\r\n")
	else
		if (self.Event[event]) then
			self.Event[event](self,from,extra)
		end
	end
	if (self.Format[event]) then
		self.Format[event](self,from,extra)
	else
		self:Display(str)
	end
end
function Connection:Timer(name,delay,reps,func,args)
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
function Connection:DoTimers()
	local Timers = self.Timers
	for k,v in pairs(Timers) do
		difference = os.time() - Timers[k].starttime
		if (difference >= Timers[k].delay) then
			if (Timers[k].reps ~= -1) then
				Timers[k].reps = Timers[k].reps - 1
				func = Timers[k].func
				Timers[k].func(self,unpack(Timers[k].args))
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
function Connection:Read()
	--Timer(tostring(self) .."_timeout",Timeout,1,self.Disconnect,{self})
	local Received,Error = self.Socket:receive()
	if (Received ~= nil) then
		self:Timer("timeout",self.Settings.Timeout,1,self.Timeout,{})
		self:Parse(Received)
	end
	if (Error ~= nil) then
		self:Display("Error: ".. Error)
		if (Error == "closed") then
			if (self.ShouldReconnect == true) then
					self:ConnectionFailure()
			end
		end
	end
end

function Connection:Timeout()
	self:Display(self.Server ..">> Connection timed out!")
	self:ConnectionFailure()
end

function Connection:ConnectionFailure()
	self.ConnectionStatus = RETRY
	if (self.Socket ~= nil) then
		self.Socket:close()
		SetObject(self.Socket,nil)
		self.Socket = nil
	end
	if (self.Retries == self.Settings.MaxRetries) then
		self:Display("Retry limt reached!")
		self.ConnectionStatus = DISCONNECTED
		Connections[tostring(self)] = nil
		self.Bot.Connections[tostring(self)] = nil
		self.Bot:ConnectionFailure(self)
	else
		self.Retries = self.Retries + 1
		self:Timer("reconnect",self.Settings.RetryDelay,1,self.Connect,{self})
	end
end


function Connection:Close()
	SetObject(self.Socket,nil)
	self.Socket:close()
	self.MessageQueue = {}
	self.ConnectionStatus = DISCONNECTED
	Connections[tostring(self)] = nil
end
	
function Connection:Quit(message)
	self:Raw("QUIT :".. (message or "") .."\r\n")
	self.ShouldReconnect = false
end
		
function Connection:Connect()
	if (self.ConnectionStatus == CONNECTED) then return end
	if (self.ConnectionStatus == DISCONNECTED) then
		self:Display("Connecting to ".. self.Server .." on port ".. self.Port ..".")
		Connections[tostring(self)] = self
		self.Socket,err = socket.connect(self.Server,self.Port)
		SetObject(self.Socket,self)
	end
	if (self.ConnectionStatus == RETRY) then
		self:Display("Connecting to ".. self.Server .." on port ".. self.Port ..". ".. self.Retries .."/".. self.Settings.MaxRetries)
		self.Socket,err = socket.connect(self.Server,self.Port)
		SetObject(self.Socket,self)
	end
	if (err ~= nil) then
		self:Display("Error connecting to ".. self.Server ..": ".. err)
		self:ConnectionFailure()
	else
		self.ConnectionStatus = CONNECTING
		self:Nick(self.Settings.Name)
		self:Raw("USER ".. self.Settings.Name .." * 8 :Sir Reddington\r\n")
		self:Timer("timeout",self.Settings.Timeout,1,self.Timeout,{self})
	end
end
Connection.Event["001"] = function(self)
	self:Raw(self.Settings.AuthCmd .."\r\n")
	self:Raw("MODE ".. self.Settings.Name .." +x\r\n")
	self:JoinChannels()
	self.ConnectionStatus = CONNECTED
	self.Retries = 0
end
Connection.Event["433"] = function(self)
	if (self.ConnectionStatus == CONNECTING) then
		local Settings = self.Settings
		if (Settings.NameIndex ~= #Settings.AltNames) then
			Settings.NameIndex = Settings.NameIndex + 1
			Settings.Name = Settings.AltNames[Settings.NameIndex]
			self:Nick(Settings.Name)
		end
	end
end
--- Tits.
Connection.Event["PRIVMSG"] = function(self,from,text)
	--self:DisplayTable(text)
	local Nick, Ident, Host = string.match(from,"(.+)%!(.+)%@(.+)")
	local To, Text = string.match(text,"(%S+)%s:(.+)")
	local argtable = {Bot = self.Bot, Connection = self, Nick = Nick, Ident = Ident, Host = Host, To = To, Text = Text}
	if (To == self.Settings.Name) then
		argtable.IsPrivate = true
	else
		argtable.IsPrivate = false
	end
	if (string.match(text,"%".. string.char(1) .."(.+)%".. string.char(1))) then --Possible CTCP
		local Command, Text = string.match(text,"%".. string.char(1) .."(.+)%".. string.char(1))
		argtable.Command = Command
		argtable.Text = Text
		if (Command == "ACTION") then
			self.Bot:DoHook("ACTION",argtable)
		else
			local res = self.Bot:DoCTCP(Command,argtable)
			if (not res) then
				self.Bot:DoHook("CTCP",argtable)
			end
		end
	else
		local res = self.Bot:DoCmd(string.match(Text,"(%S+)"),argtable)
		if (not res) then
			self.Bot:DoHook("PRIVMSG",argtable)
		end
	end
end
Connection.Format["PRIVMSG"] = function(self,from,text)
	local Nick, Ident, Host = string.match(from,"(.+)%!(.+)%@(.+)")
	local Channel, Text = string.match(text,"(%S+)%s:(.+)")
	self:Display(Nick .."@".. Channel ..": ".. Text)
end
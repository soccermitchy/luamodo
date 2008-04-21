print("--Loading Stats Module--")
-- how to use:
--	setup an http server with php and a small php script that connects to the bot on the port specified below and read and display the incoming data
-- 	the script will then dump various already formatted for display to the page (currently just dumps a table of bots active)
--	there's also the Sanitize function in case you need to prevent any injected html/javascript from being embedded into the page (such as when displaying a chatlog)
if not(Stats) then --Stuff we only need to do the first time, doing this again would probably break the bot
	Stats = Extension:New("Stats")
	Stats.Socket = socket.bind("localhost",666) --you should probably change this port
	Connections["StatServ"] = Stats
	SetObject(Stats.Socket,Stats)
end
function Stats:Read()
	local cli = Stats.Socket:accept()
	cli:send("<center>\n")
	for k,v in pairs(self.Bots) do
		cli:send("<table border=1><tr><th colspan=2><center><font size=5>".. k .."</font></center></th></tr>\n")
		cli:send("<tr><td valign=top>Connections:</td><td>&nbsp;</td></tr>")
		for k,v in pairs(v.Object.Connections) do
			cli:send("<tr><td>&nbsp;</td><td>".. v.Settings.ID ..":</td></tr>")
		end
		cli:send("</table>\n")
	end
	cli:send("</center>\n")
	cli:close()
end
function Stats:Setup(bot)
	self.Bots[bot.ID] = {}
	self.Bots[bot.ID].Object = bot
	self.Bots[bot.ID].Log = {}
end
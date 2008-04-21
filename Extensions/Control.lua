print("--Loading Control Module--")
if not(Control) then --Stuff we only need to do the first time, doing this again would probably break the bot
	Control = Extension:New("Control")
	Control.AList = {}
end
Control.PWD = "CHANGETHIS" -- the authentication password
function Control:Setup(bot)
	self.Bots[bot.ID] = {}
	self.Bots[bot.ID].Object = bot
end
Control.Cmds[1] = { --auth command, useage is !auth <password>
	Cmd = "!auth",
	Func = function(Func,Args)
		if (explode(" ",Args.Text)[2] == Control.PWD) then
			Control.AList[Args.Host] = true
			Args.Connection:Msg(Args.Nick,"Password Accepted!")
		end
	end
}
Control.Cmds[2] = { --nifty little command to reload all extensions, and also load newly added ones
	Cmd = "!reload",
	Func = function(Func,Args)
		if (Control.AList[Args.Host]) then --does the user have access?
			LoadDir("Extensions") --load every .lua file in the /Extensions/ directory
			for k,v in pairs(Extensions) do --loop through every loaded extension
				for k1,v1 in pairs(v.Bots) do --and have them reset their bot specific data
					v1.Object:LoadExtension(v)
				end
			end
		end
	end
}
Control.Cmds[3] = { --tell whatever bot recieves this command to load a specific extension
	Cmd = "!load",
	Func = function(Func,Args)
		if (Control.AList[Args.Host]) then
			Args.Bot:LoadExtension(Extensions[explode(" ",Args.Text)[2]])
		end
	end
}

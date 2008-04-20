TestBot = Bot.New("Test Bot",{"TestBot","TestBot2","TestBot3"}) --the first argument is what name to use when displaying informationg through the console, the second argument is a table of nicks to use for connections
TestBot:Connect("IRC.CHANGETHISSERVER.NET", 6667, {{channel = "#somechannel"}, {channel = "#somepasswordedchannel", password = "somepassword"}}) -- note there is another optional argument at the end, which is the command to send to the server to authenticate (such as "nickerv identify somepassword")
TestBot:LoadExtension(Stats)
TestBot:LoadExtension(Control)
TestBot:AddCTCP("VERSION", function(Func,Args) Args.Connection:CTCP(Args.Nick, "VERSION Some sort of version reply") end)
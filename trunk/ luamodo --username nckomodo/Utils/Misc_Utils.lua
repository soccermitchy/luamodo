covered = {}
Timers = {}
TableTypes = {}
TableTypes["table"] = true
SaniTable = {}
SaniTable["<"] = "&lt;"
SaniTable[">"] = "&gt;"
SaniTable["\""] = "&#34;"
SaniTable["'"] = "&#39;"
SaniTable["\\"] = "&#92;"
SaniTable["/"] = "&#47;"
SaniTable["`"] = "&#96;"
SaniTable["\r"] = ""
SaniTable["\n"] = ""
do -- modify type() to look at __type if the object has one
	local oldtype = type
	function type(object)
		if (oldtype(object) == "table") then
			mt = getmetatable(object)
			if (object.__type) then
				return object.__type
			else
				if (mt) then
					return mt.__type or oldtype(object)
				end
			end
		end
		return oldtype(object)
	end
end
function Reminder(str)
	print(str)
	os.exit()
end
function concat(tab,sep,i,j)
	if (i == nil) then
		i = 1
	end
	if (j == nil) then
		j = #tab
	end
	for k = i,j do
		tab[k] = tostring(tab[k])
	end
	return table.concat(tab,sep,i,j)
end

function Merge(table1,table2)
	for k,v in pairs(table2) do
		table1[k] = v
	end
	return table1
end
 
function AssertType(var,vartype,varname)
	assert(type(var) == vartype,"Expected ".. vartype .." for ".. varname ..", got ".. type(var))
	return var
end

function OutputTable(ttable,idchr,func,level)
	if (idchr == nil) then
		idchr = " "
	end
	if (func == nil) then
		func = print
	end
	covered[tostring(ttable)] = true
	if (level == nil) then
		level = 1
	end
	for k,v in pairs(ttable) do
		func(string.rep(idchr,level) .. tostring(k) .." = ".. tostring(v))
		if (TableTypes[type(v)]) then
			if (covered[tostring(v)] ~= true) then
				OutputTable(v,idchr,func,level + 1)
			else
				func(string.rep(idchr,level + 1) .."Already printed")
			end
		end
	end
	if (level == 1) then
		covered = {}
	end
end

function explode(div,str)
        if (div == "") then
			arr = {}
			for i = 1, string.len(str) do
				arr[i] = string.sub(str,i,i)
			end
			return arr
		end
        local pos,arr = 0,{}
        for st,sp in function() return string.find(str,div,pos,true) end do
			table.insert(arr,string.sub(str,pos,st-1))
            pos = sp + 1
        end
        table.insert(arr,string.sub(str,pos))
        return arr
end

function DoTimers()
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
	
function Timer(name,delay,reps,func,args)
	if (reps == 0) then
		reps = -1
	end
	if (delay == "off") then
		Timers[name] = nil
		return
	end
	if (name == nil) then
		error("Timer name expected for first parameter, got nil")
	end
	if (type(name) ~= "string") and (type(name) ~= "number") then
		error("String or number expected for timer name, got ".. type(name))
	end
	if (delay == nil) and (reps == nil) and (func == nil) and (args == nil) then
		if (Timers[name]) then
			local ttable = Timers[name]
			ttable.exists = true
			return ttable
		else
			return {exists = false}
		end
	end
	if (Timers[name]) then
		local ttable = {}
		ttable.delay = delay
		ttable.reps = reps
		ttable.func = func
		ttable.args = args
		ttable.starttime = os.time()
		Timers[name] = Merge(Timers[name],ttable)
		AssertType(Timers[name].delay,"number","Delay")
		AssertType(Timers[name].reps,"number","Repetitions")
		AssertType(Timers[name].func,"function","Function")
		AssertType(Timers[name].args,"table","Arguments")	
	else
		Timers[name] = {}
		Timers[name].delay = AssertType(delay,"number","Delay")
		Timers[name].reps = AssertType(reps,"number","Repetitions")
		Timers[name].func = AssertType(func,"function","Function")
		Timers[name].args = AssertType(args,"table","Arguments")
		Timers[name].starttime = os.time()
	end
end
	
function ShallowCopy(tab) --shallow copy
	rtab = {}
	for k,v in pairs(tab) do
		rtab[k] = v
	end
	return rtab
end

function DeepCopy(object)
	local lookup_table = {}
	local function _copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		local new_table = {}
		lookup_table[object] = new_table
		for index, value in pairs(object) do
			new_table[_copy(index)] = _copy(value)
		end
		return setmetatable(new_table, _copy(getmetatable(object)))
	end
	return _copy(object)
end


do
	local meta = {__call = function(t, ...)
		return t.__function(t, ...)
	end,
	__type = "TableFunc"
	}
	function TableFunc(fn)
		return setmetatable({__function = fn}, meta)
	end
end

function LoadDir(dir)
	for file in lfs.dir(dir) do
		if (file ~= ".") and (file ~= "..") and (lfs.attributes(dir .."/".. file).mode ~= "directory") and (string.match(dir .."/".. file,"(.+).lua$")) then
			dofile(dir .."/".. file)
		end
	end
end
function Sanitize(str)
	for k,v in pairs(SaniTable) do
		str = string.gsub(str,k,v)
	end
	return str
end

local assert,type=assert,type
local format=string.format

------------------------------------------------------------------------------------------------------------
-- file <------> str
------------------------------------------------------------------------------------------------------------
file2str=function(filepath)
	local f=io.open(filepath)
	assert(f,format("Invalid file path:%q",filepath))
	local str=f:read("*a")
	f:close()
	return str
end

str2file=function(str,filepath)
	local f=io.open(filepath,"w")
	assert(f,format("Invalid file path:%q",filepath))
	f:write(str)
	f:close()
	return str
end

------------------------------------------------------------------------------------------------------------
-- str <------> lua obj
------------------------------------------------------------------------------------------------------------

str2obj=function(str)
	local func=loadstring("return "..str)
	return func()
end

local tostring=tostring
local concat,push=table.concat,table.insert
local obj2str
objstr=function(obj,str)
	local tp=type(obj)
	if tp=='table' then
		local t={}
		for k,v in pairs(obj) do
			push(t,format("%s=%s",obj2str(k),obj2str(v)))
		end
		str=concat(t,",")
		return format("{%s}",str)
	elseif tp=="string" then
		return format("%q",obj)
	else
		return tostring(obj)
	end
end

------------------------------------------------------------------------------------------------------------
-- file <------> lua obj
------------------------------------------------------------------------------------------------------------

obj2file=function(obj,filepath)
	return str2file(obj2str(obj),filepath)
end

file2obj=loadfile
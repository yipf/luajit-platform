local ALL={}

local element2str=function(element)
	if type(element)=="table" then
		return "<"..table.concat(element,",")..">"
	else
		return tostring(element)
	end
end

local register_element=function(ALL,element)
    local key=element2str(element)
	if ALL[key] then ALL[key]=element end
	return key
end

local insert=function(S,element)
	S[register_element(ALL,element)]=element
end

local new=function(S,def)
	def= type(def)=="table" and def or {def}
	local s=setmetatable({},getmetatable(S))
	for k,v in pairs(def) do
		insert(s,v)
	end
	return s
end

local remove=function(S,element)
	S[register_element(ALL,element)]=nil
end

local include=function(S,element)
	return S[register_element(ALL,element)]
end

local count=function(S)
	local n=0
	for k,v in pairs(S) do
		n=n+1
	end
	return n
end

local set2str=function(S)
	local t={}
	local push=table.insert
	for key,element in pairs(S) do
		push(t,type(element)=="table" and element2str(element) or key)
	end
	return "["..table.concat(t,",").."]"
end

local clone=function(src,dst)
	return new(src,src)
end

local le=function(A,B)
	for ka,a in pairs(A) do
		if not B:include(a) then return false end
	end
	return true
end

local eq=function(A,B)
	return le(A,B) and le(B,A)
end

local union=function(A,B)
	local C=clone(A)
	for kb,b in pairs(B) do
		C:insert(b)
	end
	return C
end

local exclude=function(A,B)
	local C=clone(A)
	for kb,b in pairs(B) do
		C:remove(b)
	end
	return C
end

local intersection=function(A,B)
	local C=A:new()
	for ka,a in pairs(A) do
		if B:include(a) then C:insert(a) end
	end
	return C
end

local make_pair=function(a,b)
	local t={}
	if type(a)=="table" then
		for i,v in ipairs(a) do t[i]=v end
	else
		table.insert(t,a)
	end
	table.insert(t,b)
	return t
end

local product=function(A,B)
	local C=A:new()
	for ka,a in pairs(A) do
		for kb,b in pairs(B) do
			C:insert(make_pair(a,b))
		end
	end
	return C
end

local Set_mt={
	new=new,
	insert=insert,
	remove=remove,
	include=include,
	clone=clone,
	__tostring=set2str,
	__le=le,
	__eq=eq,
	__add=union,
	__sub=exclude,
	__mul=product,
	__pow=intersection,
}

Set_mt.__index=Set_mt

Set=setmetatable({},Set_mt)
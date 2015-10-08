
make_factory=function(key2value_func,container)
	container=container or {}
	return function(key,value)
		if not key then return container end
		if not value then
			value=container[key]
			if value then return value end
			value=key2value_func(key)
			container[key]=value
			return key
		end
		container[key]=value
	end
end
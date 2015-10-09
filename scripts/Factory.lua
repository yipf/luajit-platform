
make_factory=function(key2value_func,container)
	container=container or {}
	return function(key,value)
		if not key then return container end
		if not value then
			value=container[key]
			if not value then value=key2value_func(key)	end
		end
		container[key]=value
		return value
	end
end


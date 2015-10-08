
apply=function(func,A,B,iter)
	iter=iter or ipairs
	for k,v in iter(A) do
		B=func(v,B,k)
	end
	return B
end

make_apply_func=function(func,iter)
	local type,apply,f=type,apply
	f=function(v,B,k)
		return type(v)=='table' and apply(f,v,B,iter) or func(v,B,k)
	end
	return f
end

generic_apply=function(func,A,B,iter)
	return apply(make_apply_func(func),A,B,iter)
end

------------------------------------------------------------------------------------------------------------------------
-- test
------------------------------------------------------------------------------------------------------------------------

local add=function (a,b) return a+b end
local A={1,2,3,4,{1,2,3,4,{1,2,3,4}}}
local sum=0

print(generic_apply(add,A,sum,ipairs))



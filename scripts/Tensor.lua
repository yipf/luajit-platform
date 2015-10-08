-----------------------------------------------------------------------------------------------------------------------------------
-- c functions
-----------------------------------------------------------------------------------------------------------------------------------

local lapacke=API

-----------------------------------------------------------------------------------------------------------------------------------
-- common helper functions 
-----------------------------------------------------------------------------------------------------------------------------------
local assert,setmetatable,getmetatable,pairs,type,rawequal,tonumber=assert,setmetatable,getmetatable,pairs,type,rawequal,tonumber

local dims2sizes=function(dims,order)
	order=order or #dims
	local sizes={[order+1]=1}
	for i=order,1,-1 do
		sizes[i]=dims[i]*sizes[i+1]
	end
	return sizes
end

local ids2pos=function(ids,sizes,order)
	if type(ids)=='table' then
		assert(#ids==order,"The number of ids must equal the order of the tensor!")
		local pos=0
		for i,v in ipairs(ids) do		pos=pos+(v-1)*sizes[i+1]	end
		return pos
	else
		return ids-1
	end
end

local cvalue=lapacke.alloc_data(1)

local make_data=function(n,value,data)
	data=data or lapacke.alloc_data(n)
	if value then
		if type(value)=="table" then
			for i=1,n do				data[i-1]=value[i] or 0			end
		else
			cvalue[0]=tonumber(value)
			lapacke.set_values(n,cvalue,0,data,1)
		end
	end
	return data
end

local tensor_new=function(T,dims,value)
	value=value or T
	dims=type(dims)=='table' and dims or {dims}
	local order=#dims
	local sizes=dims2sizes(dims)
	local N=sizes[1]
	assert(order>0,"A tensor's order should not less than one!'")
	local t={dims=dims,sizes=sizes,order=order,data=make_data(N,value),N=N}
	return setmetatable(t,getmetatable(T))
end

local tensor_clone=function(src,dst)
	dst=dst or tensor_new(src,src.dims)
	lapacke.set_values(dst.N,src.data,1,dst.data,1)
	return dst
end

local tensor_get=function(src,ids)
	return src.data[ids2pos(ids,src.sizes,src.order)]
end

local tensor_set=function(dst,ids,value)
	dst.data[ids2pos(ids,dst.sizes,dst.order)]=value
end

----------------------------------------------------------------------------------
-- high level functions
----------------------------------------------------------------------------------

local array_eq=function(A,B)
	if not rawequal(#A,#B) then return false end
	for i,v in ipairs(A) do if not rawequal(A,B) then return false end end
	return true
end

tensor_eq=function(A,B)
	if rawequal(A,B) then return true end
	return rawequal(A.order,B.order) and array_eq(A.dims,B.dims) and lapacke.equal(A.N,A.data,1,B.data,1)~=0 and getmetatable(A)==getmetatable(B)
end

local map_cdata=function(f,n,da,db,dc)
	dc=dc or lapacke.alloc_data(n)
	for i=0,n-1 do		dc[i]=f(da[i],db[i])	end
end

local mapTT=function(f,n,A,B,C)	
	for i=0,n-1 do C[i]=f(A[i],B[i]) end 
end

local mapTS=function(f,n,A,b,C)	
	for i=0,n-1 do C[i]=f(A[i],b) end
end

local map=function(f,A,B,C) -- C=f(A,B)
	local n=A.N
	if type(B)=="table"  then -- if B is a tensor
		assert(A.order==B.order and array_eq(A.dims,B.dims),"The two tensor must be the same type!")
		C=C or tensor_new(A,A.dims)
		mapTT(f,A.N,A.data,B.data,C.data)
		return C
	else
		C=C or tensor_new(A,A.dims)
		mapTS(f,A.N,A.data,tonumber(B),C.data)
		return C
	end
end

local reduce=function(f,A,value) -- value=f(A,value)
	local n,data=A.N,A.data
	for i=0,n-1 do	data[i]=f(data[i],value)	end
	return value
end

local add=function(a,b) return a+b end
local sub=function(a,b) return a+b end
local mul=function(a,b) return a*b end

local tensor_mul=function(A,B)
	local o1,o2=A.order,type(B)=='table' and B.order
	if o2 and o1<3 and o1>=o2 then
		if o1==1 then -- o1=o2=1
			return lapacke.dot(A.N,A.data,1,B.data,1) 
		elseif o2==1 then 	-- o1=2, o2=1
			local m,n=unpack(A.dims)
			assert(n==B.N,"An mxn matrix can only multiple with an n-length vector!")
			local C=tensor_new(A,m)
			lapacke.gemv(m,n,A.data,B.data,1,C.data,1)
			return C
		else -- o1=o2=2
			local am,an=unpack(A.dims)
			local bm,bn=unpack(B.dims)
			assert(an==bm,"An mxn matrix can only multiple with an nxl matrix!")
			local C=tensor_new(A,{am,bn})
			lapacke.gemm(am,an,bn,A.data,B.data,C.data)
			return C
		end
	end
	return map(mul,A,B)
end

local transpose=function(A,TA)
	local m,n=unpack(A.dims)
	TA=TA or tensor_new(A,{n,m},0)
	lapacke.transpose(m,n,A.data,TA.data)
	return TA
end

local cell2str=function(data)
	return type(data)=="table" and "<"..table.concat(data,",")..">" or tostring(data)
end

local tensor2str
tensor2str=function(tensor,level,pos)
	level=level or 1
	pos=pos or 0
	local order,dims=tensor.order,tensor.dims
	local t,str={}
	if level<order then
		local sizes=tensor.sizes
		for i=1,dims[level] do
			t[i]=tensor2str(tensor,level+1,pos+(i-1)*sizes[level+1])
		end
		str="[\n"..table.concat(t,"\n").."\n]"
	else
		for i=1,dims[level] do
			t[i]=cell2str(tensor.data[pos+i-1])
		end
		str="["..table.concat(t,"\t").."]"
	end
	return str
end

local tensor_svd=function(mat)
	assert(mat.order==2,"The SVD operation must be performed on a matrix!")
	local m,n=unpack(mat.dims)
	local min=math.min(m,n)
	local U,S,VT,superb=tensor_new(mat,{m,m}),tensor_new(mat,{min}),tensor_new(mat,{n,n}),lapacke.alloc_data(min)
	local info=lapacke.svd(m,n,mat.data,U.data,S.data,VT.data,superb)
	lapacke.destroy_data(superb)
	return U,S,VT
end

local tensor_mt={
	clone=tensor_clone,
	set=tensor_set,
	get=tensor_get,
	map=map,
	reduce=reduce,
	transpose=transpose,
	svd=tensor_svd,

	__tostring=tensor2str,
	__eq=tensor_eq,
	__add=function(A,B) return map(add,A,B) end,
	__sub=function(A,B) return map(sub,A,B) end,
	__mul=tensor_mul,
	__call=tensor_new,
}
tensor_mt.__index=tensor_mt

Tensor=setmetatable({1;order=1,dims={1},sizes={1}},tensor_mt)
Vector=Tensor
Matrix=Tensor

local values_=function(tensor,i)
	i=i+1
	if i<tensor.N then return i,tensor.data[i] end
end

values=function(tensor)
	return values_,tensor,-1
end
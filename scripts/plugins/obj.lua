-------------------------------------------------------------------
-- load function
-------------------------------------------------------------------

local push=table.insert
local obj_str2index=function(str)
	local t={}
	for num in string.gmatch(str,"[^/]") do
		push(t)
	end
	return t
end

local path2DirNameExt=function(str)
	local dir,name,ext=string.match(str,"^(.*%/)([^%/]-)$")
	if not dir then 
		dir="./";	name=fullpath;
	end
	str=name
	name,ext=string.match(str,"^(.*)%.([^%.]-)$")
	if not name then
		name=str 	ext=""
	end
	return dir,name,ext
end

local gmatch,match=string.gmatch,string.match
local obj_key_hooks
obj_key_hooks={
	['v']=function(str,dst)
		local t={}
		for w in gmatch(str,"%S+") do push(t,tonumber(w)) end
		push(dst.V,t)
		return dst
	end,
	['vt']=function(str,dst)
		local t={}
		for w in gmatch(str,"%S+") do push(t,tonumber(w)) end
		push(dst.T,t)
		return dst
	end,
	['vn']=function(str,dst)
		local t={}
		for w in gmatch(str,"%S+") do push(t,tonumber(w)) end
		push(dst.N,t)
		return dst
	end,
	['f']=function(str,dst)
		local V,T,N=dst.V,dst.T,dst.N
		local vs={}
		local v
		for element in gmatch(str,"%S+") do
			v={}
			for index in gmatch(element.."/","([^/]*)/") do
				push(v,tonumber(index) or 0)
			end
			push(vs,v)
		end
		push(dst,{"face",vs})
		return dst
	end,
	['mtllib']=function(path,dst,dir)
		file2table(dir..path,dst.MTL,obj_key_hooks,dir,"^%s*(.-)%s+(.-)%s*$")
		return dst
	end,
	['usemtl']=function(key,dst)
		push(dst,{"mtl",dst.MTL[key]})
		return dst
	end,
	--- hooks for stlfile
	['newmtl']=function(key,dst,dir)
		local mtl={}
		dst[key]=mtl
		dst.CURRENT=mtl
		return dst
	end,
	['map_Kd']=function(path,dst,dir)
		local mtl=dst.CURRENT
		mtl["map_Kd"]={"file",dir..path}
		return mtl
	end,
}

local match=string.match
local load_obj=function(filepath,hooks)
	local dir,name,ext=path2DirNameExt(filepath)
	local f=io.open(filepath)
	assert(f,string.format("Not a valid file %q",filepath))
	print(string.format("Loading model from %q",filepath))
	local obj={V={},T={[0]={0,0}},N={},MTL={}}
	local match,key,value=string.match
	for line in f:lines() do
			key,value=match(line,"^%s*(.-)%s+(.-)%s*$") do
			key=hooks[key]
			if key then key(value,obj,dir) end
		end
	end
	f:close()
	return obj
end

-------------------------------------------------------------------
-- draw function
-------------------------------------------------------------------

local combine=function(arr)
	local x,y,z=0,0,0
	for i,v in ipairs(arr) do
		x=x+v[1]
		y=y+v[2]
		z=z+v[3]
	end
	local s=x*x+y*y+z*z
	s= s==0 and 0 or 1/math.sqrt(s)
	return {x*s,y*s,z*s}
end

local gen_normal=function(v1,v2,v3)
	local x1,y1,z1=v2[1]-v1[1], v2[2]-v1[2], v2[3]-v1[3];	
	local x2,y2,z2=v3[1]-v2[1], v3[2]-v2[2], v3[3]-v2[3];
	local x,y,z=y1*z2-y2*z1,z1*x2-z2*x1,x1*y2-x2*y1
	local s=x*x+y*y+z*z
	s= s==0 and 0 or 1/math.sqrt(s)
	return {x*s,y*s,z*s}
end

local append_normals=function(vids,V,n)
	assert(n>2)
	local v1,v2,v3=V[vids[1]],V[vids[2]],V[vids[3]]
	local normal=gen_normal(v1,v2,v3)
	local target,normals
	local push=table.insert
	for i=1,n do
		target=V[vids[i]]
		normals=target.normals or {}
		push(normals,normal)
		target.normals=normals
	end
	return V
end

local compute_normal=function(obj)
	if obj.NORMAL_COMPLETE then return obj end
	local V=obj.V
	local key,value
	local vids={}
	for i,v in ipairs(obj) do
		key,value=unpack(v)
		if key=="face" then
			for i,vertice in ipairs(value) do
				vids[i]=vertice[1]
			end
			append_normals(vids,V,#value)
		end
	end
	for i,v in ipairs(V) do
		v.normal=combine(v.normals)
	end
	obj.NORMAL_COMPLETE=true
	return obj
end

local computer_texcoord=function(obj)
	if obj.TEXCOORD_COMPLETE then return obj end
	for i,v in ipairs(obj.V) do
		v.texcoord={0.5,0.5}
	end
	obj.TEXCOORD_COMPLETE=true
	return obj
end

local draw_obj=function(obj)
	local key,value
	local V,T,N=obj.V,obj.T,obj.N
	local vid,tid,nid
	for i,v in ipairs(obj) do
		key,value=unpack(v)
		if key=="mtl" then 
--~ 			apply_material(value)
		elseif key=="face" then
			API.begin_draw(#value==4 and API.QUADS or API.TRIANGLE_STRIP)
			for ii,vertice in ipairs(value) do
				vid,tid,nid=unpack(vertice)
				vid=V[vid]
				if not tid then 
					computer_texcoord(obj) 
					tid=vid.texcoord
				else
					tid=T[tid]
				end
				if not nid then
					compute_normal(obj)
					nid=vid.normal
				else
					nid=N[nid]
				end
				API.set_vertex(vid[1],vid[2],vid[3],tid[1],tid[2],nid[1],nid[2],nid[3])
			end
			API.end_draw()
		end
	end
end

require "3d"

local f=function(drawer)
	local data=drawer.data
	data= data or load_obj(drawer[2],obj_key_hooks)
	draw_obj(data)
end

register_drawer_hook("obj",f)


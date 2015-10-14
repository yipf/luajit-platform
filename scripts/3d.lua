require "Factory"

local API=API
local type,assert,format=type,assert,string.format

local drawer_hooks,texture_hooks={},{}

drawfunc2calllist=function(...)
	local id=API.gen_list_begin()
	pcall(...)
	API.gen_list_end()
	return id
end

drawfunc2calllist_func=function(func)
	local id=drawfunc2calllist(func)
	return function() API.call_list(id) end
end

drawer2func=function(drawer)
	drawer=type(drawer)=="table" and drawer or {drawer}
	local key=drawer[1]
	assert(key,"Please define a valid drawer!")
	local hook=drawer_hooks[key]
	assert(hook,format("Not a valid drawer type %q !",key))
	return function() hook(drawer) end
end

Drawers=make_factory(drawer2func)

material2func=function(material)
	local texture=material.texture or material
	local key=texture[1]
	assert(key,"Please define a valid texture!")
	local hook=texture_hooks[key]
	assert(hook,format("Not a valid texture type %q !",key))
	local id=hook(texture)
	return function() API.apply_texture(id) end
end

Materials=make_factory(material2func)

shaderfile2id=function(filepath)
	local vert,frag=dofile(filepath)
	return API.build_shader(vert,frag)
end

Shaders=make_factory(shaderfile2id)

local API=API

local ipairs=ipairs

local do_each=function(children,func)
	if children then
		for i,child in ipairs(children) do
			func(child)
		end
	end
end

local draw_node_
draw_node_=function(node)
	local matrix,material,drawer=node.matrix,node.material,node.drawer
	API.push_matrix(matrix)
	if material then material() end
	if drawer then drawer() end
	do_each(node.children,draw_node_)
	API.pop_matrix(matrix)
	return node
end

local init_node_
init_node_=function(node)
	local drawer,material,children=node.drawer,node.material,node.children
	if drawer then node.drawer=Drawers(drawer)  end
	if drawer.COMPILE then node.drawer=drawfunc2calllist_func(node.drawer) end
	if material then node.material=Materials(material)  end
	do_each(node.children,init_node_)
	return node
end

local update_node_
update_node_=function(node)
	local action,children=node.action,node.children
	if action then action(node) end
	do_each(node.children,update_node_)
	return node
end

draw_node,init_node,update_node=draw_node_,init_node_,update_node_

------------------------------------------------------------------------------------------------------------
-- texture hooks
------------------------------------------------------------------------------------------------------------

texture_hooks["file"]=function(texture)
	return API.imgfile2texture(texture[2])
end

texture_hooks["color"]=function(texture)
	local color=texture[2]
	color= type(color)=="table" and color or {color}
	local r,g,b,a=unpack(color)
	r=r or 255 	g=g or 255 	b=b or 255 	a=a or 255
	local img=API.create_mem_img(1,1)
	img[0],img[1],img[2],img[3]=r,g,b,a
	return API.mem_img2texture(img,1,1,0)
end

------------------------------------------------------------------------------------------------------------
-- drawer hooks
------------------------------------------------------------------------------------------------------------

node_hook=function(node)
	init_node(node)
	return draw_node(node)
end
drawer_hooks["node"]=node_hook

drawer_hooks["nodefile"]=function(filepath)
	local node=dofile(filepath)
	return node_hook(node)
end

drawer_hooks["plane"]=function(drawer)
	local r=drawer[2] or 1
	API.begin_draw(API.QUADS)
	API.set_vertex(r,0,r,0.0,0.0,0,1,0)
	API.set_vertex(r,0,-r,0.0,1.0,0,1,0)
	API.set_vertex(-r,0,-r,1.0,1.0,0,1,0)
	API.set_vertex(-r,0,r,1.0,0.0,0,1,0);
	API.end_draw()
end

drawer_hooks["box"]=function(drawer)
	local r=drawer[2] or 1
	API.begin_draw(API.QUADS)
	API.set_vertex(r,r,r,0,0,0,1,0);API.set_vertex(r,r,-r,0,1,0,1,0);API.set_vertex(-r,r,-r,1,1,0,1,0);API.set_vertex(-r,r,r,1,0,0,1,0);
	API.set_vertex(r,-r,r,0,0,0,-1,0);API.set_vertex(-r,-r,r,0,1,0,-1,0);API.set_vertex(-r,-r,-r,1,1,0,-1,0);API.set_vertex(r,-r,-r,1,0,0,-1,0);
	API.set_vertex(-r,r,r,0,0,-1,0,0);API.set_vertex(-r,r,-r,0,1,-1,0,0);API.set_vertex(-r,-r,-r,1,1,-1,0,0);API.set_vertex(-r,-r,r,1,0,-1,0,0);
	API.set_vertex(r,r,r,0,0,1,0,0);API.set_vertex(r,-r,r,0,1,1,0,0);API.set_vertex(r,-r,-r,1,1,1,0,0);API.set_vertex(r,r,-r,1,0,1,0,0);
	API.set_vertex(r,r,r,0,0,0,0,1);API.set_vertex(-r,r,r,0,1,0,0,1);API.set_vertex(-r,-r,r,1,1,0,0,1);API.set_vertex(r,-r,r,1,0,0,0,1);
	API.set_vertex(r,r,-r,0,0,0,0,-1);API.set_vertex(r,-r,-r,0,1,0,0,-1);API.set_vertex(-r,-r,-r,1,1,0,0,-1);API.set_vertex(-r,r,-r,1,0,0,0,-1);
	API.end_draw()
end

require "Shapes"

drawer_hooks["grid"]=function(drawer)
	local grid=drawer[2]
	attach_normals(grid)
	attach_texcoords(grid)
	draw_grid_raw(grid)
end

local circle=make_arc(0.5,11,0,math.rad(330),true)

drawer_hooks["path"]=function(drawer)
	local base=drawer.base or circle
	local grid=drawer.grid or path2grid(drawer[2],base)
	attach_normals(grid)
	attach_texcoords(grid)
	draw_grid_raw(grid)
	drawer.grid,drawer.base=grid,base
end
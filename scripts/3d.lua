require "Factory"

local API=API
local type,assert,format=type,assert,string.format

local drawer_hooks,texture_hooks={},{}

drawer2func=function(drawer)
	drawer=type(drawer)=="table" and drawer or {drawer}
	local key=drawer[1]
	assert(key,"Please define a valid drawer!")
	local hook=drawer_hooks[key]
	assert(hook,format("Not a valid drawer type %q !",key))
	if drawer.COMPILE then
		local id=API.gen_list_begin()
		hook(drawer)
		API.gen_list_end()
		return function()
			API.call_list(id)
		end
	end
	return function() hook(drawer) end
end

Drawers=make_factory(drawer2func)

register_drawer_hook=function(key,hook)
	drawer_hooks[key]=hook
end

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
	if drawer and type(drawer)=="table" then node.drawer=Drawers(drawer)  end
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

drawer_hooks["mesh"]=function(drawer)
	draw_mesh(drawer[2])
end

drawer_hooks["particle"]=function(drawer)
	local func,positions,matrix=drawer.draw_func,drawer.positions,drawer.matrix
	if not func then
		func=Drawers(drawer[2])
		drawer.draw_func=func
	end
	if not matrix then
		matrix=API.make_translate(nil,0,0,0)
		drawer.matrix=matrix
	end
	if positions then
		for i,pos in ipairs(positions) do
			matrix[12],matrix[13],matrix[14]=pos[1],pos[2],pos[3]
			API.push_matrix(matrix)
			func()
			API.pop_matrix(matrix)
		end
	end
end


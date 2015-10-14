
require 'iupluagl'
require '3d'

--- config btn
local CONFIG_STR=[[
Scene %t
Shadow: %b
Texture: %b
Alpha: %b
Background: %c
Light %t
Enable: %b
x: %r
y: %r
z: %r
Draw %t
Cull Face: %b[no,yes]
Mode: %b[Line,Fill]
Shade: %b[Flat,Smooth]
]]

local API=API

local light_camera=API.create_camera3d(0)
light_camera=API.set_camera_projection(light_camera,1,1000,math.rad(90),1)
light_camera=API.update_camera(light_camera)

local default_mouse_func=function(x,y)
	
end

require "utils"

local str2table=str2table

local print_data=function(str,data,pos,n,step)
	n,step=n or 1,step or 1
	local t,s={}
	print(str)
	for i=1,n do
		s=pos+(i-1)*step
		for j=1,step do			t[j]=data[s+j-1]			end
		print(table.concat(t,"\t"))
	end
end

local print_camera=function(camera)
	print_data("X",camera,API.VEC_X,1,4)
	print_data("Y",camera,API.VEC_Y,1,4)
	print_data("Z",camera,API.VEC_Z,1,4)
	print_data("T",camera,API.VEC_T,1,4)
	print_data("PROJECTION",camera,API.PROJECTION,4,4)
	print_data("VIEW",camera,API.VIEW,4,4)
	print_data("BIAS",camera,API.BIAS,4,4)
end


make_gl_canvas=function(scn,camera,w,h)
	local cfg=scn.config or {"Config The Opengl Windows",0,1,0,"65 105 225",1,1,2,1,1,1,1}
	local MakeCurrent,SwapBuffer,Update=iup.GLMakeCurrent,iup.GLSwapBuffers,iup.Update
	local isleft,ismiddle,isright,isshift=iup.isbutton1,iup.isbutton2,iup.isbutton3,iup.isshift
	local click_func,move_func=scn.click_func or default_mouse_func,scn.move_func or default_mouse_func
	
	local mouse_xy={0,0}
	local F1,FORWARD,BACKWARD,LEFT,RIGHT,UP,DOWN,ZOOM_IN,ZOOM_OUT,RESET=iup.K_F1,iup.K_w,iup.K_s,iup.K_a,iup.K_d,iup.K_q,iup.K_e,iup.K_z,iup.K_x,iup.K_r
	local init
	
	local ray,cp=API.alloc_data(8),API.alloc_data(4)
	
	local step,rate=1
	local glcanvas
	
	local light_shader=scn.light_shader
	local light=true
	
	local shadow_FBO
	local rgba={}
	
	local apply_cfg=function(cfg)
		local s,fog,a,bg,l,x,y,z,cf,mode,shade=unpack(cfg,2)
		local op=0
		if a==1 then op=op+API.BLEND end
		if fog==1 then op=op+API.TEXTURE_2D end
		if l==1 then 
			op=op+API.LIGHTING 
			light=true
		else
			light=false
		end
		if cf==1 then op=op+API.CULL_FACE end
		if mode==1 then op=op+API.FILL end
		if shade==1 then op=op+API.SMOOTH end
		API.apply_options(op)
		-- setting up light
		scn.light_matrix[12]=x 	scn.light_matrix[13]=y 	scn.light_matrix[14]=z 	
		API.set_camera_position(light_camera,x,y,z)
		API.register_light_pos(0,x,y,z,1)
		if x+z~=0 then 
			API.set_camera_direction(light_camera,-x,-y,-z,0,1,0)
		else
			API.set_camera_direction(light_camera,-x,-y,-z,1,0,0)
		end
		API.update_camera(light_camera)
		rgba=str2table(bg,"%S+",rgba)
		local r,g,b,a=unpack(rgba)
		API.set_bg_color(tonumber(r or 0)/255,tonumber(g or 0)/255,tonumber(b or 0)/255, tonumber(a or 0)/255)
		Update(glcanvas)
	end
	
	local init_scn,draw_scn=init_node,draw_node
	
	glcanvas=iup.glcanvas{ buffer="DOUBLE", rastersize = w..'x'..h,
		map_cb=function(o)
			MakeCurrent(o)
			if not init then -- init the opengl context via gle-init
				API.init_opengl() 
				shadow_FBO=API.create_shadowFBO(2048,2048)
				init=true 
			end
			init_scn(scn) -- init scene
			if scn.prepare then init_scn(scn.prepare) end
			light_shader= Shaders("scripts/Shaders/spot-light&shadow.shader") or 0
			apply_cfg(cfg) 
			API.set_viewport(0,0,w,h)
		end,
		action=function(o)
			MakeCurrent(o)
			API.clear_buffers()
			if light then 
				API.prepare_render_shadow(light_camera,shadow_FBO)
				draw_scn(scn)
				API.bind_shadow2shader(light_camera,shadow_FBO,light_shader)
				API.prepare_render_normal(camera)
			else
				API.apply_shader(0)
				API.camera_look(camera)
			end
			draw_scn(scn)
			SwapBuffer(o)
		end,
		resize_cb=function(o,w_,h_)
			MakeCurrent(o)
			API.set_viewport(0,0,w_,h_)
			API.resize_camera(camera,(h_/w_)/(h/w),1)
			w,h=w_,h_
			Update(o)
		end,
		-- mouse callbacks
		wheel_cb=function (o,delta,x,y,status)
			rate=delta>0 and 0.9 or 1.11
			API.scale_camera(camera,rate)
			API.update_camera(camera)
			Update(o)
		end,
		motion_cb=function(o,x,y,status)
			if isright(status) then -- if right bottun down
				local mx,my=unpack(mouse_xy)
				if mx then
					API.rotate_camera(camera,(mx-x)*0.01,(y-my)*0.01)
					API.update_camera(camera)
					Update(o)
				end
				mouse_xy[1],mouse_xy[2]=x,y
				return true
			elseif isleft(status) and move_func then
				x,y=x/w-0.5, 0.5-y/h
				API.camera3d_xy2ray(camera,x*2,y*2,ray)
				move_func(org,dir,cp,camera)
				Update(o)
				return true
			end
			-- otherwise, clear the mouse
			mouse_xy[1]=nil
		end,
		button_cb=function(o,but, pressed, x, y, status)-- mouse button
			if pressed==1 and isleft(status) and click_func then
				x,y=x/w-0.5, 0.5-y/h
				API.camera3d_xy2ray(camera,x*2,y*2,ray)
				click_func(org,dir,cp)
				Update(o)
				return true
			end
		end,
		-- key board callbacks
		keypress_cb=function(o,k,pressed)
			step=0.02
			API.move_camera(camera,k==LEFT and -step or k==RIGHT and step or 0, k==UP and step or k==DOWN and -step or 0, k==FORWARD and -step or k==BACKWARD and step or 0)
			rate= k==ZOOM_OUT and 0.9 or k==ZOOM_IN and 1.11
			if rate then API.resize_camera(camera,rate,rate) end
			if k==RESET then API.set_camera_position(camera,0,0,0) end
			API.update_camera(camera)
			Update(o)
			return true
		end,
	}
	return glcanvas,make_cfg_btn("Graphic Config",CONFIG_STR,cfg,apply_cfg)
end

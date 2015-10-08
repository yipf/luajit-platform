require 'iupluagl'

require 'lua-common/strstr'
require '3D/drawers'
require '3D/textures'
require '3D/shaders'
local API=API

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
local light_camera=API.create_camera()
light_camera=API.make_camera(light_camera,0,0,0,0)
light_camera=API.set_camera_projection(light_camera,1,1000,math.rad(90),1)
light_camera=API.update_camera(light_camera)

make_gl_canvas=function(scn,camera,w,h)
	local cfg=scn.config or {"Config The Opengl Windows",0,1,0,"65 105 225",1,1,2,1,1,1,1}
	local MakeCurrent,SwapBuffer,Update=iup.GLMakeCurrent,iup.GLSwapBuffers,iup.Update
	local isleft,ismiddle,isright,isshift=iup.isbutton1,iup.isbutton2,iup.isbutton3,iup.isshift
	local click_func,move_func=scn.click_func,scn.move_func
	
	local mouse_xy={0,0}
	local F1,FORWARD,BACKWARD,LEFT,RIGHT,UP,DOWN,ZOOM_IN,ZOOM_OUT,RESET=iup.K_F1,iup.K_w,iup.K_s,iup.K_a,iup.K_d,iup.K_q,iup.K_e,iup.K_z,iup.K_x,iup.K_r
	local init
	
	local org,dir,cp=API.create_vec4(0,0,0),API.create_vec4(0,0,0),API.create_vec4(0,0,0)
	
	local step,rate=1
	local glcanvas
	
	local light_shader=scn.light_shader
	local light=true
	
	local shadow_render
	
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
		API.gl_options(op)
		API.gl_set_light(0,x,y,z,0)
		API.set_camera_position(light_camera,x,y,z)
		if x+z~=0 then 
			API.set_camera_direction(light_camera,-x,-y,-z,0,1,0)
		else
			API.set_camera_direction(light_camera,-x,-y,-z,1,0,0)
		end
		API.update_camera(light_camera)
		local t=str2table(bg,"%S+",tonumber)
		local r,g,b,a=unpack(t)
		API.gl_set_bg_color(r or 0,g or 0,b or 0, a or 255)
		Update(glcanvas)
	end
	local init_scn,draw_scn=init_scn,draw_scn
	local shaders=Shaders
	
	glcanvas=iup.glcanvas{ buffer="DOUBLE", rastersize = w..'x'..h,
		map_cb=function(o)
			MakeCurrent(o)
			if not init then -- init the opengl context via gle-init
				API.my_init() 
				shadow_render=API.create_render(2048,2048,API.DEPTH)
				init=true 
			end
			init_scn(scn) -- init scene
			if scn.prepare then init_scn(scn.prepare) end
			light_shader=light_shader and shaders(light_shader) or 0
			apply_cfg(cfg) 
			API.gl_set_viewport(0,0,w,h)
		end,
		action=function(o)
			MakeCurrent(o)
			API.gl_clear_all()
			if light then 
				API.build_shadowmap(light_camera,shadow_render)
				draw_scn(scn)
				API.bind_shadowmap(light_camera,light_shader,shadow_render)
				API.camera_look(camera)
			else
				API.camera_look(camera)
				API.apply_shader(0) 
			end
			draw_scn(scn)
			SwapBuffer(o)
		end,
		resize_cb=function(o,w_,h_)
			MakeCurrent(o)
			API.gl_set_viewport(0,0,w_,h_)
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
				API.xy2ray(camera,x*2,y*2,org,dir)
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
				API.xy2ray(camera,x*2,y*2,org,dir)
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

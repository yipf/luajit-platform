
require "3d"

local light_matrix=API.make_translate(nil,0,0,0)


local light={drawer={"box",0.1;COMPILE=true},matrix=light_matrix}

local rot=API.make_rotate(nil,1,1,1,math.rad(3))
local mat=API.make_translate(nil,0,0.4,0)

local box1={drawer={"box",0.3;COMPILE=true},material={"color",{255,255,0}},matrix=mat,
action=function()
   API.mm3d(mat,rot,mat)
end}

local scn={
light_matrix=light_matrix,
drawer={"plane",3,COMPILE=true},
material={"color",{255,255,255}},
children={light,box1},
}

local update_scn=update_node



------------------------------------------------------------------------------------------
-- UI
------------------------------------------------------------------------------------------

require "UI/widgets"

local dialog,split,frame,vbox,tabs=iup.dialog,iup.split,iup.frame,iup.vbox,iup.tabs
 
require 'UI/gl_canvas'

local API=API
local camera=API.create_camera3d(10)
camera=API.set_camera_projection(camera,1,1000,math.rad(60),1)
camera=API.update_camera(camera)

local glw,gl_cfg=make_gl_canvas(scn,camera,800,800)
local gl_panel=frame{title="GL",glw}


local Update=iup.Update
local timer_toggle,timer=make_timer("timer",30,function()
    update_scn(scn)
	Update(glw)
end)

-- main dialog

local about_str=[[
YIPF Copyright

2008-2013
]]

local tabs=tabs{ expand="yes",
 vbox{tabtitle="Operation",expand='yes',gl_cfg,timer_toggle,make_space()},
 vbox{tabtitle="Option",expand='yes',cfg_btn,make_space()},
 vbox{tabtitle="About",expand='yes',make_space(about_str)},
}

local op_panel=frame{title="Operations",size="200x400",tabs,expand='yes'}

local dlg=dialog{title="my",iup.split{gl_panel,op_panel;orientation='verticle'}}

dlg:show()
 
if (not iup.MainLoopLevel or iup.MainLoopLevel()==0) then
  iup.MainLoop()
end

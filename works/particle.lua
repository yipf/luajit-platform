
require "3d"

require "plugins/obj"

local dragon_drawer={"obj","data/dragon.obj",COMPILE=true}

local mat=API.make_translate(nil,-1,0.5,0.5)
local dragon1={drawer=dragon_drawer,matrix=mat,material={"color",{255,0,0}}}

local mat=API.make_translate(nil,-1,0.5,-0.5)
local dragon2={drawer=dragon_drawer,matrix=mat,material={"color",{255,255,0}}}


local g=-0.0002
local pos={{0,2,0,0}}
local action=function()
    local life
    for i,v in ipairs(pos) do
        life=v[4] or 1
        if v[2]>0 then
            v[2]=v[2]+life*life*g
        else
            v[2]=math.random(100)/100*2
            life=0
        end
        life=life+1
        v[4]=life
    end
end
local stream={drawer={"particle",{"box",0.05,COMPILE=true},positions=pos},material={"color",{0,0,255}},action=action}

local light_matrix=API.make_translate(nil,0,0,0)
local light={drawer={"box",0.1;COMPILE=true},matrix=light_matrix}




local scn={
light_matrix=light_matrix,
drawer={"plane",3},
material={"color",{255,255,255}},
--~ children={light,dragon1,dragon2,water},
children={light,dragon1,dragon2,stream},
}

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
local update_node=update_node
local timer_toggle,timer=make_timer("timer",30,function()
    update_node(scn)
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

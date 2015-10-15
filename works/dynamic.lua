
require "3d"



require "plugins/obj"

local dragon_drawer={"obj","data/dragon.obj",COMPILE=true}

local mat=API.make_translate(nil,0,1,0)
local dragon1={drawer=dragon_drawer,matrix=mat,material={"color",{255,0,0}}}

local mat=API.make_translate(nil,-1,1,0)
local dragon2={drawer=dragon_drawer,matrix=mat,material={"color",{255,255,0}}}

require "Shapes"

local sin,cos=math.sin,math.cos
local N=30
local dr,da=0.3,math.rad(360)/N
local water_grid=create_grid(10,N,true,false,function(i,j)
      local r,a=dr*(i-1),da*(j-1)
      return r*cos(a),0,r*sin(a)
end)

local ROUND,ang=math.rad(360),0

local h=0.1
local action=function()
    ang=ang + 0.01
    while ang>ROUND do ang=ang-ROUND end
    for i,row in ipairs(water_grid) do
        for j,cell in ipairs(row) do
            cell[1]=h*sin(ang*i)
        end
    end
    grid2mesh(water_grid)
end

local water={drawer={"mesh",grid2mesh(water_grid)},material={"color",{255,0,255}},action=action}

local light_matrix=API.make_translate(nil,0,0,0)
local light={drawer={"box",0.1;COMPILE=true},matrix=light_matrix}

local scn={
light_matrix=light_matrix,
material={"color",{255,255,255}},
--~ children={light,dragon1,dragon2,water},
children={light,water},
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

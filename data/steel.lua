require "luagl"

local rad,cos,sin=math.rad,math.cos, math.sin
local Normal,TexCoord,Vertex,Begin,End= gl.Normal,gl.TexCoord,gl.Vertex,gl.Begin,gl.End

local D_PI=rad(360)

local draw_steal_round=function(r1,r2,step,depth)
	r1,r2,step,depth=r1 or 10, r2 or 20 , step or 30, depth or 10
	local c,s
	-- inner face
	Begin("TRIANGLE_STRIP")
		for i=0,360,step  do
			i=rad(i)
			c,s=cos(i),sin(i)
			Normal(-c,-s,0)
			TexCoord(1,i/D_PI);	Vertex(c*r1,s*r1,-depth);
			TexCoord(0,i/D_PI);	Vertex(c*r1,s*r1,depth);
		end
	End()
	-- outter face
	Begin("TRIANGLE_STRIP")
		for i=0,360,step  do
			i=rad(i)
			c,s=cos(i),sin(i)
			Normal(c,s,0)
			TexCoord(1,i/D_PI);	Vertex(c*r2,s*r2,depth);
			TexCoord(0,i/D_PI);	Vertex(c*r2,s*r2,-depth);
		end
	End()
	-- front face
	Begin("TRIANGLE_STRIP")
		for i=0,360,step  do
			i=rad(i)
			c,s=cos(i),sin(i)
			Normal(0,0,1)
			TexCoord(0,i/D_PI);	Vertex(c*r1,s*r1,depth);
			TexCoord(1,i/D_PI);	Vertex(c*r2,s*r2,depth);
		end
	End()
	-- back face
	Begin("TRIANGLE_STRIP")
		for i=0,360,step  do
			i=rad(i)
			c,s=cos(i),sin(i)
			Normal(0,0,-1)
			TexCoord(1,i/D_PI);	Vertex(c*r2,s*r2,-depth);
			TexCoord(0,i/D_PI);	Vertex(c*r1,s*r1,-depth);
		end
	End()
	print(r1,r2,step,depth)
	return true
end

return {
	{drawer="box 10 1 1",},
	{drawer="box 1 10 1",},
	{drawer={"script",draw_steal_round,10,12,30,1},},
}
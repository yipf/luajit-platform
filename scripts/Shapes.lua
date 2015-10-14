print_array=function(arr,t)
	t=t or {}
	for i,v in ipairs(arr) do
		t[i]="["..v[0]..","..v[1]..","..v[2].."]"
	end
	print(table.concat(t,"\t"))
end

print_grid=function(mat,t)
	t=t or {}
	for i,row in ipairs(mat) do
		print_v3d_array(row,t)
	end
end

create_points1d=function(n)
	local points1d={}
	for i=1,n do	points1d[i]=API.alloc_data(4)	end
	return points1d
end

create_points2d=function(m,n)
	local points2d={}
	for i=1,m do		points2d[i]=create_points1d(n)	end
	return points2d
end

create_curve=function(n,closed,func)
	local curve=create_points1d(n)
	if func then
		for i,cell in ipairs(curve) do
			cell[0],cell[1],cell[2]=func(i)
		end
	end
	curve.N,curve.closed=n,closed
	return curve
end

create_grid=function(m,n,u_closed,v_closed,func)
	local grid=create_points2d(m,n)
	if func then
		for i,row in ipairs(grid) do
			for j,cell in ipairs(row) do
				cell[0],cell[1],cell[2]=func(i,j)
			end
		end
	end
	grid.M,grid.N,grid.u_closed,grid.v_closed=m,n,u_closed,v_closed
	return grid
end

diff3d=function(curve,closed,T)
	local n=#curve
	assert(n>1,"At least 2 points needed to compute tangent! ")
	T=T or create_points1d(n)
	API.sub3d(curve[2],closed and curve[n] or curve[1],T[1])
	for i=2,n-1 do
		API.sub3d(curve[i+1],curve[i-1],T[i])
	end
	API.sub3d(closed and curve[1] or curve[n],curve[n-1],T[n])
	return T
end

attach_normals=function(grid)
	local m,n,u_closed,v_closed=grid.M,grid.N,grid.u_closed,grid.v_closed
	local normals,temp=grid.normals or create_points2d(m,n),grid.temp or create_points1d(n)
	local N
	for i,row in ipairs(grid) do
		temp=diff3d(row,u_closed,temp)
		N=normals[i]
		for j,v in ipairs(N) do
			API.sub3d(grid[i==m and (v_closed and 1 or i) or i+1][j] , grid[i==1 and (v_closed and m or i) or i-1][j],v) 	-- n= grid[r+1][col]-grid[r-1][col]
			API.cross3d(temp[j],v,v) 	
			API.normalize3d(v)
		end
	end
	grid.normals,grid.temp=normals,temp
	return grid
end

attach_texcoords=function(grid,us,vs)
	local m,n,u_closed,v_closed=grid.M,grid.N,grid.u_closed,grid.v_closed
	grid.us=us or grid.us or samples(0,1,u_closed and n or (n-1))
	grid.vs=vs or grid.vs or samples(0,1,v_closed and m or (m-1))
	return grid
end

print_vertex=function(v,n,tx,ty)
	print("V:",v[0],v[1],v[2],"N:",n[0],n[1],n[2],"T:",tx,ty)
end

local draw_strip=function(n,V1,N1,V2,N2,U1,U2,v1,v2,closed)
	API.begin_draw(API.TRIANGLE_STRIP)
	for i=1,n do
		API.set_vertex_v(V1[i],N1[i],U1[i],v1)
		API.set_vertex_v(V2[i],N2[i],U2[i],v2)
	end
	if closed then
		API.set_vertex_v(V1[1],N1[1],U1[n+1],v1)
		API.set_vertex_v(V2[1],N2[1],U2[n+1],v2)		
	end
	API.end_draw()
end

require "utils"

draw_grid_raw=function(grid)
	local m,n,u_closed,v_closed=grid.M, grid.N, grid.u_closed, grid.v_closed
	local normals,us,vs=grid.normals,grid.us,grid.vs
	for i=1,m-1 do
		draw_strip(n,grid[i+1],normals[i+1],grid[i],normals[i],us,us,vs[i+1],vs[i],u_closed)
		if v_closed then
			draw_strip(n,grid[1],normals[1],grid[m],normals[m],us,us,vs[m+1],vs[m],u_closed)
		end
	end
	return grid
end

curve2path=function(curve,path)
	local closed=curve.closed
	local Z=diff3d(curve,closed)
	local Y=diff3d(Z,closed)
	path=path or {}
	local x,y,z,p
	for i,v in ipairs(curve) do
		z=Z[i]		y=Y[i]
		x=API.cross3d(y,z,nil)
		y=API.cross3d(z,x,y)
		path[i]={API.normalize3d(x),API.normalize3d(y),API.normalize3d(z),v}
	end
	path.closed=curve.closed
	return path
end

path2grid=function(path,curve)
	local m,n=#path,#curve
	local grid=create_grid(m,n)
	local XYZT
	for i,row in ipairs(grid) do
		XYZT=path[i]
		for j,v in ipairs(row) do
			API.applyXYZT(curve[j],v,unpack(XYZT))
		end
	end
	grid.v_closed,grid.u_closed=path.closed,curve.closed
	return grid
end

--------------------------------------------------------------------------------------------
-- special functions
--------------------------------------------------------------------------------------------

make_arc=function(r,n,s,e,closed)
	r,n=r or 1,n or 3
	s,e=s or 0,e or math.rad(270)
	local angs=samples(s,e,n)
	local arc=create_curve(n,closed)
	local cos,sin=math.cos,math.sin
	local ang
	for i,v in ipairs(arc) do
		ang=angs[i]
		v[0],v[1],v[2]=r*cos(ang),r*sin(ang),0
	end
	return arc
end



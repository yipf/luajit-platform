local assert,setmetatable,getmetatable,pairs,type,rawequal=assert,setmetatable,getmetatable,pairs,type,rawequal

local graph_new=function(G,V,E,directed)
	local E={}
	local g={directed=directed,E=E}
	V=V or G
	if type(V)~="table" then
		V=tonumber(V) or 1
		for i=1,V do g[i]=i;	end
	else
		for i,v in ipairs(V) do			g[i]=v; 	end
	end
	return setmetatable(g,getmetatable(G))
end

graph_set_edge=function(G,from,to)
	local n,E=#G,G.E
	assert(from<=n and to<=n, "Both from and to must be in Vertex set!")
	local edges=E[from]
	if not to or not edges then edges={};	E[from]=edges end
	edges[to]=from
	return G
end

graph2str=function(G)
	local t,arrow={},G.directed and "\t-->\t" or "\t<-->\t"
	local push=table.insert
	push(t,"Vertex:\t["..table.concat(G,",").."]")
	for from,edges in pairs(G.E) do
		for to,v in pairs(edges) do
			push(t,"edge:\t"..from..arrow..to)
		end
	end
	return table.concat(t,"\n")
end

local graph_mt={
	set_edge=graph_set_edge,
	__call=graph_new,
	__tostring=graph2str,
}
graph_mt.__index=graph_mt

Graph=setmetatable({1,E={}},graph_mt)

---------------------------------------------------------------------------------
-- test
---------------------------------------------------------------------------------

print(Graph)

local G=Graph(10,nil,true)

G:set_edge(1,2)
G:set_edge(3,4)

print(G)

require "scripts/Tensor"

----------------------------------------------------------------------------------
-- test
----------------------------------------------------------------------------------



local E=function(str)
	local obj=loadstring("return "..str)()
	print(str,"=",obj)
end


A=Tensor({1,6},{1,2,3,4,5,6})

for i,v in values(A) do
	print(i,v)
end


E"A"

B=A:clone()

E"A==B"

A:set({1,1},3)
E"A"
C=A+B

E"C"
E"A==A"

C,D=Vector(3,4),Vector(3,2)
E"C"
E"D"
E"C*D"

 e=A:transpose()

E"A*0.05"
 
E"e"

Mat,V=Matrix({2,2},{1,2,3,-4}),Vector(2,10)

E"Mat*V"

local A=Tensor({6,5},{
            8.79,  9.93,  9.83, 5.45,  3.16,
            6.11,  6.91,  5.04, -0.27,  7.98,
           -9.15, -7.93,  4.86, 4.85,  3.01,
            9.57,  1.64,  8.83, 0.74,  5.80,
           -3.49,  4.02,  9.80, 10.00,  4.27,
            9.84,  0.15, -8.99, -6.02, -5.31
        })
		
print(A)

local u,s,vt=A:svd()

print(u)
print(s)
print(vt)

MAT=Matrix({4,2},{2,4,1,3})
E"MAT"

local u,s,vt=MAT:svd()
print(u)
print(s)
print(vt)

local S=Matrix({4,2},{[1]=s:get(1),[4]=s:get(2)})
print(S)

local mmm=u*S*vt
print(mmm)

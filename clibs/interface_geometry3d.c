
#include "interface_opengl.h"
#include <math.h>

scalar* diff3d(int n,scalar* A, int astep,scalar* D,int dstep,int close){ /* D=diff(A) */
	int i;
	scalar *pA,*pB,*pD;
	D=D?D:alloc_data(n);
	if(n<2){ return 0;}
	if(n==2){
		sub3d(A+astep,A,D);
		sub3d(A+astep,A,D+dstep);
		return D;
	}
	/* n>2 */
	for(i=1;i<n-1;i++){ sub3d(A+(i+1)*astep,A+(i-1)*astep,D+i*dstep); }
	sub3d(A+astep,close?(A+(n-1)*astep):A,D);
	sub3d(close?A:(A+(n-1)*astep),A+(n-2)*astep,D+(n-1*dstep));
	return D;
}

scalar* test_ray_hit_sphere(scalar* ray, scalar* sphere, scalar* temp){
	scalar t,r,*org,*dir;
	org=ray;	dir=ray+3;
	OP3ABC(temp,=,org,-,sphere);
	t=dot3d(temp,dir);
	if(t>=0.0) return 0;
	OP3ABC(temp,=,temp,-,t*dir)
	r=sphere[3];
	if(dot3d(temp,temp)>r*r) return 0;
	temp[3]=-t;
	return temp;
}

scalar* ray_hit_plane(scalar* ray,scalar* plane, scalar* crosspoint){
	scalar t1,t2,*org,*dir,*point,*N;
	org=ray;	dir=ray+3;
	point=plane;	N=plane+3;
	t1=dot3d(dir,N);
	t2=dot3d(point,N)-dot3d(org,N);
	if(t1<0.0 && t2<0.0){ /* if (point-ray.org)*plane.normal<0 then it is possible to cross  */
		t1=t2/t1;
		OP3ABC(crosspoint,=,org,+,t1*dir) 
		return crosspoint;
	}
	return 0;
}


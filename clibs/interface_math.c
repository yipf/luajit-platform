#include "interface_math.h"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <lapacke.h>

scalar* alloc_data(int n){
	scalar* data;
	data=calloc(n,sizeof(scalar));
	return data;
}

scalar* get_ptr(scalar* data,int offset){
	return data+offset;
}

void destroy_data(scalar* data){
	free(data);
}

int set_values(int n,scalar* x,int xstep,scalar* y,int ystep){ 
	while(n--){y[n*ystep]=x[n*xstep];}
	return 0;
}

scalar dot(int n,scalar* x,int xstep,scalar* y,int ystep){
	scalar sum=0;
	while(n--){sum+=x[n*xstep]*y[n*ystep];}
	return sum;
}

scalar* gemv(int m,int n,scalar* M, scalar* V,int vstep,scalar* MV,int mvstep){
	MV=MV?MV:alloc_data(m);
	while(m--){MV[m*mvstep]=dot(n,M+m*n,1,V,vstep);} /* MV[m]=dot(M[m*],V) */
	return MV;
}

scalar* gemm(int m,int n,int k,scalar* A, scalar* B,scalar* AB){
	int i;
	AB=AB?AB:alloc_data(m*k);
	i=k;
	while(i--){ gemv(m,n,A,B+i,k,AB+i,k);	} /* AB[*i]=A*B[*i] */
	return AB;
}

int equal(int n,scalar* x,int xstep,scalar* y,int ystep){
	while(n--&&x[n*xstep]==y[n*ystep]);
	return n<0;
}

scalar* transpose(int m,int n, scalar* A,scalar* AT){
	int i;
	AT=AT?AT:alloc_data(n*m);
	i=m;
	while(i--){		set_values(n,A+i*n,1,AT+i,m);	 } /* AT[*i]=A[i*] */
	return AT;
}

int svd(int m, int n, scalar* A,scalar* U,scalar* S,scalar* VT,scalar* superb){
	return LAPACKE_dgesvd( LAPACK_ROW_MAJOR, 'A','A',m,n,A,n,S,U,m,VT,n,superb);
}

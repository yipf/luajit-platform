#ifndef INTERFACE_MATH_H
#define INTERFACE_MATH_H

typedef double scalar;

scalar* alloc_data(int n);

scalar* get_ptr(scalar* data,int offset);
void destroy_data(scalar* data);

int set_values(int n,scalar* x,int xstep,scalar* y,int ystep);

scalar dot(int n,scalar* x,int xstep,scalar* y,int ystep);

scalar* gemv(int m,int n,scalar* M, scalar* V,int vstep,scalar* MV,int mvstep);

scalar* gemm(int m,int n,int k,scalar* A, scalar* B,scalar* AB);
int equal(int n,scalar* x,int xstep,scalar* y,int ystep);
scalar* transpose(int m,int n, scalar* A,scalar* AT);
int svd(int m, int n, scalar* A,scalar* U,scalar* S,scalar* VT,scalar* superb);


#endif
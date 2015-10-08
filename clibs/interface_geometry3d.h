#ifndef INTERFACE_GEOMETRY3D_H
#define INTERFACE_GEOMETRY3D_H

#include "math.h"
\

/* special functions */

scalar* diff3d(int n,scalar* A, int astep,scalar* D,int dstep,int close); 	/* D=diff(A) */

/* geometry */

scalar* test_ray_hit_sphere(scalar* ray, scalar* sphere,  scalar* temp);/* test if the ray hit a given sphere which centered ar center with radius r. if hit then return camera*/

scalar* ray_hit_plane(scalar* ray,scalar* plane, scalar* crosspoint);/* compute the crosspoint cp between a given ray and a  */

#endif
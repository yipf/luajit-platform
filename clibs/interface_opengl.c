#include "interface_opengl.h"

#include "interface_image.h"

#include <stdlib.h>
#include <stdio.h>
#include <math.h>

scalar dot3d(scalar* A,scalar* B){
	return A[0]*B[0]+A[1]*B[1]+A[2]*A[2];
}

scalar* cross3d(scalar* A,scalar* B, scalar* C){
	scalar x1,y1,z1,x2,y2,z2;
	x1=A[0];	y1=A[1];	z1=A[2];	
	x2=B[0];	y2=B[1];	z2=B[2];	
	C=C?C:alloc_data(4);
	C[0]=y1*z2-y2*z1;
	C[1]=z1*x2-z2*x1;
	C[2]=x1*y2-x2*y1;
	return C;
}

scalar* sub3d(scalar *A,scalar *B,scalar *C){
	C=C?C:alloc_data(4);
	OP3ABC(C,=,A,-,B);
	return C;
}

scalar* add3d(scalar *A,scalar *B,scalar *C){
	C=C?C:alloc_data(4);
	OP3ABC(C,=,A,+,B);
	return C;
}

scalar* normalize3d(scalar*A, scalar*NA){
	scalar s;
	s=dot3d(A,A);
	if(s==0) return 0;
	s=1.0/sqrt(s);
	NA=NA?NA:alloc_data(4);
	OP3AB(NA,=,s*A)
	return NA;
}

scalar* make_rotate(scalar* mat,scalar x,scalar y, scalar z, scalar ang){
	scalar n,s,c;
	n=sqrt(x*x+y*y+z*z);	s=sin(ang);	c=cos(ang);
	x=x/n;	y=y/n;	z=z/n;	
	mat=mat?mat:alloc_data(16);
	mat[0]=x*x*(1-c)+c;		mat[4]=x*y*(1-c)-z*s;		mat[8]=x*z*(1-c)+y*s;	mat[12]=0;
	mat[1]=x*y*(1-c)+z*s;	mat[5]=y*y*(1-c)+c;		mat[9]=y*z*(1-c)-x*s;	 	mat[13]=0;
	mat[2]=x*z*(1-c)-y*s;		mat[6]=y*z*(1-c)+x*s;	mat[10]=z*z*(1-c)+c;		mat[14]=0;
	mat[3]=0;						mat[7]=0	;					mat[11]=0;						mat[15]=1;
	return mat;
}


scalar* make_scale(scalar* mat,scalar sx,scalar sy,scalar sz){
	mat=mat?mat:alloc_data(16);
	mat[0]=sx;	mat[1]=0;	mat[2]=0;	mat[3]=0;
	mat[4]=0;	mat[5]=sy;	mat[6]=0;	mat[7]=0;
	mat[8]=0;	mat[9]=0;	mat[10]=sz;	mat[11]=0;
	mat[12]=0;	mat[13]=0;	mat[14]=0;	mat[15]=1;
	return mat;
}
scalar* make_translate(scalar* mat,scalar tx,scalar ty,scalar tz){
	mat=mat?mat:alloc_data(16);
	mat[0]=1;	mat[1]=0;	mat[2]=0;	mat[3]=0;
	mat[4]=0;	mat[5]=1;	mat[6]=0;	mat[7]=0;
	mat[8]=0;	mat[9]=0;	mat[10]=1;	mat[11]=0;
	mat[12]=tx;	mat[13]=ty;	mat[14]=tz;	mat[15]=1;
	return mat;
}

scalar* mm3d(scalar* A,scalar* B,scalar* AB){ /* A*(Bv)=AB*v*/
	AB=AB?AB:alloc_data(16);
	scalar a11,a21,a31,a41,a12,a22,a32,a42,a13,a23,a33,a43,a14,a24,a34,a44;
	scalar b11,b12,b13,b14,b21,b22,b23,b24,b31,b32,b33,b34,b41,b42,b43,b44;
	/*get A*/
	a11=A[0];a21=A[1];a31=A[2];a41=A[3];
	a12=A[4];a22=A[5];a32=A[6];a42=A[7];
	a13=A[8];a23=A[9];a33=A[10];a43=A[11];
	a14=A[12];a24=A[13];a34=A[14];a44=A[15];
	/*get B*/
	b11=B[0];b21=B[1];b31=B[2];b41=B[3];
	b12=B[4];b22=B[5];b32=B[6];b42=B[7];
	b13=B[8];b23=B[9];b33=B[10];b43=B[11];
	b14=B[12];b24=B[13];b34=B[14];b44=B[15];
	/* AB=A*B */
	AB[0]=a11*b11+a12*b21+a13*b31+a14*b41;
	AB[1]=a21*b11+a22*b21+a23*b31+a24*b41;
	AB[2]=a31*b11+a32*b21+a33*b31+a34*b41;
	AB[3]=a41*b11+a42*b21+a43*b31+a44*b41;
	
	AB[4]=a11*b12+a12*b22+a13*b32+a14*b42;
	AB[5]=a21*b12+a22*b22+a23*b32+a24*b42;
	AB[6]=a31*b12+a32*b22+a33*b32+a34*b42;
	AB[7]=a41*b12+a42*b22+a43*b32+a44*b42;
	
	AB[8]=a11*b13+a12*b23+a13*b33+a14*b43;
	AB[9]=a21*b13+a22*b23+a23*b33+a24*b43;
	AB[10]=a31*b13+a32*b23+a33*b33+a34*b43;
	AB[11]=a41*b13+a42*b23+a43*b33+a44*b43;
	
	AB[12]=a11*b14+a12*b24+a13*b34+a14*b44;
	AB[13]=a21*b14+a22*b24+a23*b34+a24*b44;
	AB[14]=a31*b14+a32*b24+a33*b34+a34*b44;
	AB[15]=a41*b14+a42*b24+a43*b34+a44*b44;

	return AB;
}

scalar* mv3d(scalar* M,scalar* V,scalar* MV){
	scalar m11,m21,m31,m41,m12,m22,m32,m42,m13,m23,m33,m43,m14,m24,m34,m44;
	scalar v1,v2,v3,v4;
	MV=MV?MV:alloc_data(4);
	m11=M[0];m21=M[1];m31=M[2];m41=M[3];
	m12=M[4];m22=M[5];m32=M[6];m42=M[7];
	m13=M[8];m23=M[9];m33=M[10];m43=M[11];
	m14=M[12];m24=M[13];m34=M[14];m44=M[15];
	v1=V[0];v2=V[1];v3=V[2];v4=V[3];
	MV[0]=m11*v1+m12*v2+m13*v3+m14*v4;
	MV[1]=m21*v1+m22*v2+m23*v3+m24*v4;
	MV[2]=m31*v1+m32*v2+m33*v3+m34*v4;
	MV[4]=m41*v1+m42*v2+m43*v3+m44*v4;
	return MV;
}

camera3d_t create_camera3d(void){
	camera3d_t camera;
	scalar* data;
	data=calloc(80,sizeof(scalar));
	camera=data;
	camera[POS_DIST]=1; /* camera's dist = 1 */
	make_translate(data,0,0,0); 	/*init X,Y,Z,T*/
	make_translate(data+PROJECTION,0,0,0); 	 /*init PROJECTION*/
	make_translate(data+VIEW,0,0,0); 	 /*init VIEW*/
	 /* init BIAS*/
	data=data+BIAS;
	data[0]=0.5;	data[1]=0;	data[2]=0;	data[3]=0;
	data[4]=0;	data[5]=0.5;	data[6]=0;	data[7]=0;
	data[8]=0;	data[9]=0;	data[10]=0.5;	data[11]=0;
	data[12]=0.5;	data[13]=0.5;	data[14]=0.5;	data[15]=1;
	return camera;
}

camera3d_t move_camera(camera3d_t camera,scalar right, scalar up, scalar back){
	scalar rate;
	scalar *V,*T,*data;
	T=camera+VEC_T; 	rate=camera[POS_DIST];
	if(right!=0){ 	right*=rate; V=data+VEC_X; T[0]+=right*V[0];T[1]+=right*V[1];T[2]+=right*V[2];} /* T=T0+right*X */
	if(up!=0){up*=rate; T[1]+=up;}
	if(back!=0){back*=rate; V=data+VEC_Z; T[0]+=back*V[0];T[2]+=back*V[2];}
	return camera;
}

static scalar PI=3.1415926535898;
static scalar D_PI=6.2831853071796;

camera3d_t rotate_camera(camera3d_t camera,scalar dh,scalar dv){
	scalar h,v,hc,hs,vc,vs;
	scalar *x,*y,*z;
	h=camera[POS_H]+dh; v=camera[POS_V]+dv;
	while(h>PI)h-=D_PI;	while(h<-PI)h+=D_PI;	
	while(v>PI)v-=D_PI;	while(v<-PI)v+=D_PI;	
	x=camera+VEC_X;	y=camera+VEC_Y;	z=camera+VEC_Z;
	hc=cos(h);	hs=sin(h);	vc=cos(v);	vs=sin(v);
	z[0]=hs*vc;	z[1]=vs;	z[2]=hc*vc;
	x[0]=hc;x[1]=0;x[2]=-hs;
	y=cross3d(z,x,y);
	camera[POS_H]=h;	camera[POS_V]=v;
	return camera;
}

camera3d_t scale_camera(camera3d_t camera,scalar s){
	camera[POS_DIST]*=s;
	return camera;
}

camera3d_t set_camera_position(camera3d_t camera, scalar x, scalar y, scalar z){
	scalar* T;
	T=camera+VEC_T;
	T[0]=x; 	T[1]=y; 	T[2]=z; 	
	return camera;
}

camera3d_t resize_camera(camera3d_t camera, scalar w, scalar h){
	scalar* projection;
	projection=camera+PROJECTION;
	projection[0]*=w; 	projection[5]*=h;
	return camera;
}

/* http://blog.csdn.net/gnuser/article/details/5146598 */
camera3d_t set_camera_projection(camera3d_t camera,scalar near,scalar far,scalar fov,scalar wh){
	scalar* projection;
	scalar right,top;
	projection=camera+PROJECTION;
	top=near*tan(fov/2);	right=wh*top;
	projection[0]=near/right;		projection[1]=0;					projection[2]=0;		projection[3]=0;
	projection[4]=0;						projection[5]=near/top;		projection[6]=0;		projection[7]=0;
	projection[8]=0;						projection[9]=0;					projection[10]=(far+near)/(near-far);	projection[11]=-1;
	projection[12]=0;					projection[13]=0;				projection[14]=2*far*near/(near-far);	projection[15]=0; 
	return camera;
}

camera3d_t set_camera_direction(camera3d_t camera, scalar x, scalar y, scalar z,scalar upx,scalar upy,scalar upz){
	scalar* X,*Y,*Z;
	X=camera+VEC_X; 	Y=camera+VEC_X; 	Z=camera+VEC_Z;
	Z[0]=-x;	Z[1]=-y;	Z[2]=-z;
	Y[0]=upx; Y[1]=upy;	Y[2]=upz;
	cross3d(Y,Z,X); 	cross3d(Z,X,Y);
	normalize3d(X,X); normalize3d(Y,Y); normalize3d(Z,Z); 
	return camera;
}

camera3d_t update_camera(camera3d_t camera){
	scalar *view,*X,*Y,*Z,*T,*V;
	scalar d;
	view=camera+VIEW;
	X=camera+VEC_X; 	Y=camera+VEC_Y;  	Z=camera+VEC_Z;  	T=camera+VEC_T; 
	d=camera[POS_DIST];
	V=camera+VEC_TEMP;
	V[0]=-d*Z[0]-T[0]; V[1]=-d*Z[1]-T[1];	V[2]=-d*Z[2]-T[2];
	// get invert matrix 
	view[0]=X[0];				view[1]=Y[0];				view[2]	=Z[0];			view[3]=0;
	view[4]=X[1];				view[5]=Y[1];				view[6]	=Z[1];			view[7]=0;
	view[8]=X[2];				view[9]=Y[2];				view[10]	=Z[2];			view[11]=0;
	view[12]=dot3d(V,X);	view[13]=dot3d(V,Y);	view[14]=dot3d(V,Z);	view[15]=1;	
	return camera;
}

camera3d_t camera_look(camera3d_t camera){
	/* set projection matrix*/
	glMatrixMode(GL_PROJECTION);
	glLoadMatrixd(camera+PROJECTION);
	glMultMatrixd(camera+VIEW);
	 /* set modelview matrix*/
	glMatrixMode(GL_MODELVIEW);
	//~ glLoadIdentity();
	return camera;
}

scalar*  camera3d_xy2ray(camera3d_t camera, scalar x, scalar y,scalar* ray){ /* compute a ray <org,dir> from (x,y) in viewport, where org is stored at camera+VEC_ORG, and dir is stored at camera+VEC_DIR*/
	scalar d,*projection,*X,*Y,*Z,*T,*org,*dir;
	ray=ray?ray:alloc_data(6);
	org=ray;	dir=ray+3;
	X=camera+VEC_X; 	Y=camera+VEC_Y;  	Z=camera+VEC_Z;  	T=camera+VEC_T; 
	d=camera[POS_DIST]; 	projection=camera+PROJECTION;
	OP3ABC(org,=,T,+,d*Z);
	x/=projection[0]; y/=projection[5];
	OP3ABC(dir,=,x*X,+,y*Y);
	OP3ABC(dir,=,dir,-,Z);
	normalize3d(dir,dir);
	return ray;
}

unsigned char* create_mem_img(unsigned int width, unsigned int height){
	return calloc(width*height,sizeof(unsigned char));
}

GLuint mem_img2texture(unsigned char* data,unsigned int width, unsigned int height,int linear){
	GLuint id;
	glGenTextures(1, &id);
	glBindTexture(GL_TEXTURE_2D, id );
	glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width,height, 0,  GL_RGBA, GL_UNSIGNED_BYTE, data );
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,linear?GL_LINEAR:GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,linear?GL_LINEAR:GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
	return id;
}

GLuint imgfile2texture(char const *filepath){
	GLuint id;
	unsigned int w,h,comp;
	unsigned char *data;
	data=stbi_load(filepath,&w,&h,&comp,4);
	if(!data){
		printf("Error when loading file: %s",filepath);
		return 0;
	}
	id=mem_img2texture(data,w, h,1);
	free(data);
	return id;
}

GLuint apply_texture(GLuint id){
	if(id){		glBindTexture(GL_TEXTURE_2D,id);	}
	return id;
}

int init_opengl(void){
	GLenum glew_state;
	/* initiate glew*/
	glew_state=glewInit();
	if(GLEW_OK!=glew_state) {printf("Error Loading GLEW: %d",GLEW_OK);return 1;}
	/* initiate opengl environment */
	glClearDepth(1.0);            // Depth Buffer Setup
	glEnable(GL_DEPTH_TEST);   // Enables Depth Testing
	glDepthFunc(GL_LEQUAL);    // The Type Of Depth Testing To Do
	glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST);
	glFrontFace(GL_CCW);
	glEnable(GL_NORMALIZE);
	glAlphaFunc(GL_GREATER,0.1); 
	glEnable(GL_TEXTURE_2D); // always enable textures
	return 0;
}

int set_viewport(int x,int y,int w, int h){
	glViewport(x,y,w,h);
	return 0;
}

int apply_options(int op){
	if(op&TEXTURE_2D){glEnable(GL_TEXTURE_2D);}else{ glDisable(GL_TEXTURE_2D);}
	if(op&LIGHTING){glEnable(GL_LIGHTING);}else{ glDisable(GL_LIGHTING);}
	if(op&CULL_FACE){glEnable(GL_CULL_FACE);}else{ glDisable(GL_CULL_FACE);}
	if(op&BLEND){glEnable(GL_BLEND);}else{ glDisable(GL_BLEND);}
	if(op&FOG){glEnable(GL_FOG);}else{ glDisable(GL_FOG);}
	if(op&FILL){glPolygonMode(GL_FRONT_AND_BACK,GL_FILL);}else{glPolygonMode(GL_FRONT_AND_BACK,GL_LINE);}
	if(op&SMOOTH){glShadeModel(GL_SMOOTH);}else{glShadeModel(GL_FLAT);}
	return 0;
}


GLhandleARB compile_shader(const char* string,GLenum type){
	GLhandleARB handle;
	GLint result;				// Compilation code result
	GLint errorLoglength;
	char* errorLogText;
	GLsizei actualErrorLogLength;
	handle = glCreateShaderObjectARB(type);
	if (!handle){
		printf("Failed creating shader object!");
		return 0;
	}
	glShaderSourceARB(handle, 1, &string, 0);
	glCompileShaderARB(handle);
	//Compilation checking.
	glGetObjectParameterivARB(handle, GL_OBJECT_COMPILE_STATUS_ARB, &result);
	if (!result)
	{
		printf("Failed to compile shader:");
		glGetObjectParameterivARB(handle, GL_OBJECT_INFO_LOG_LENGTH_ARB, &errorLoglength);
		errorLogText = malloc(sizeof(char) * errorLoglength);
		glGetInfoLogARB(handle, errorLoglength, &actualErrorLogLength, errorLogText);
		printf("%s\n",errorLogText);
		free(errorLogText);
	}
	return handle;
}

GLhandleARB build_shader(const char* vert,const char* frag){
	GLhandleARB shadowShaderId;
	shadowShaderId = glCreateProgramObjectARB();
	glAttachObjectARB(shadowShaderId,vert?compile_shader(vert,GL_VERTEX_SHADER):0);
	glAttachObjectARB(shadowShaderId,frag?compile_shader(frag,GL_FRAGMENT_SHADER):0);
	glLinkProgramARB(shadowShaderId);
	return shadowShaderId;
}

GLuint* create_shadowFBO(GLuint width,GLuint height){
	GLuint* FBO;
	FBO=calloc(4,sizeof(GLuint));
	FBO[2]=width;	FBO[3]=height;
	/* create a depth texture */
	glEnable(GL_TEXTURE_2D);
	glGenTextures(1, FBO+1);
	glBindTexture(GL_TEXTURE_2D,FBO[1]);
	glTexImage2D(GL_TEXTURE_2D,0,GL_DEPTH_COMPONENT,width,height,0,GL_DEPTH_COMPONENT,GL_UNSIGNED_BYTE,NULL);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP);  
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_CLAMP);  
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);  
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);  
	/* bind texture to FBO */
	glGenFramebuffersEXT(1, FBO);
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, FBO[0]);
	glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_TEXTURE_2D, FBO[1], 0);
	return FBO;
}

int prepare_render_shadow(camera3d_t light,GLuint* shadowFBO){
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, shadowFBO[0]);
	glPushAttrib(GL_VIEWPORT_BIT | GL_COLOR_BUFFER_BIT);
	glClear( GL_DEPTH_BUFFER_BIT);
	glViewport(0,0,shadowFBO[2],shadowFBO[3]);
	glCullFace(GL_FRONT); // only draw back faces
	glUseProgramObjectARB(0);
	camera_look(light);
}

int bind_shadow2shader(camera3d_t light,GLuint* shadowFBO,GLuint shader){
	glPopAttrib();
	glCullFace(GL_BACK);
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glUseProgramObjectARB(shader);
	glActiveTextureARB(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_2D, shadowFBO[1]);
	glUniform1iARB(glGetUniformLocationARB(shader,"shadowmap"),  1); 
	glUniform1iARB(glGetUniformLocationARB(shader,"tex"),  0); 
	glMatrixMode(GL_TEXTURE);
	glLoadIdentity();	
	glLoadMatrixd(light+BIAS);
	glMultMatrixd(light+PROJECTION);
	glMultMatrixd(light+VIEW);
	glActiveTextureARB(GL_TEXTURE0);
}

int prepare_render_normal(camera3d_t camera){
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
	camera_look(camera);
	return 0;
}

int end_normal_reander(void){
	return 0;
}

GLuint gen_list_begin(){
	GLuint id;
	id = glGenLists (1);
	glNewList(id, GL_COMPILE);
	return id;
}

GLuint gen_list_end(){
	glEndList();
}

GLuint call_list(GLuint id){
	if(id){ 	glCallList(id); }
	return id;
}

scalar* push_matrix(scalar* matrix){
	if(matrix){		glPushMatrix();		glMultMatrixd(matrix);	}
	return matrix;
}

scalar* pop_matrix(scalar* matrix){
	if(matrix){		glPopMatrix();	}
	return matrix;
}

int begin_draw(int type){
	switch(type){
		case POINTS: glBegin(GL_POINTS); break;
		case LINES: glBegin(GL_LINES); break;
		case POLYGON: glBegin(GL_POLYGON); break;
		case TRIANGLES: glBegin(GL_TRIANGLES); break;
		case QUADS: glBegin(GL_QUADS); break;
		case LINE_STRIP: glBegin(GL_LINE_STRIP); break;
		case LINE_LOOP: glBegin(GL_LINE_LOOP); break;
		case TRIANGLE_STRIP: glBegin(GL_TRIANGLE_STRIP); break;
		case TRIANGLE_FAN: glBegin(GL_TRIANGLE_FAN); break;
		case QUAD_STRIP: glBegin(GL_QUAD_STRIP); break;
		default: break;
	}
	return type;
}
int end_draw(void){
	glEnd();
}

int set_vertex(scalar x,scalar y,scalar z, scalar tx,scalar ty,scalar nx, scalar ny, scalar nz){
	glTexCoord2f(tx,ty);
	glNormal3f(nx,ny,nz);
	glVertex3f(x,y,z);
	return 0;
}
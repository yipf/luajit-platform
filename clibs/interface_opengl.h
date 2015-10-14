#ifndef INTERFACE_OPENGL_H
#define INTERFACE_OPENGL_H

#include "interface_math.h"
#include <GL/glew.h>

#define OP3ABC(C,eq,A,op,B) 	C[0] eq A[0] op B[0];	C[1] eq A[1] op B[1];	C[2] eq A[2] op B[2];
#define OP3AB(B,eq,A) 	B[0] eq A[0] ;	B[1] eq A[1] ;	B[2] eq A[2] ;

#define ASSERT(state,msg,value) if(state){printf("\n%s:%d:\t%s\n ",__FILE__,__LINE__,#state);printf(msg); return value;}

/* vector */

scalar dot3d(scalar* A,scalar* B); 	/* return dot(A,B) */
scalar* cross3d(scalar* A,scalar* B, scalar* C); /* C=cross(A,B)	*/

scalar* sub3d(scalar *A,scalar *B,scalar *C); 	/* C=A-B */
scalar* add3d(scalar *A,scalar *B,scalar *C); 	/* C=A+B */
scalar* normalize3d(scalar*A);

/* matrix (column-major)*/

scalar* make_rotate(scalar* mat,scalar x,scalar y, scalar z, scalar ang);
scalar* make_scale(scalar* mat,scalar sx,scalar sy,scalar sz);
scalar* make_translate(scalar* mat,scalar tx,scalar ty,scalar tz);

scalar* mm3d(scalar* A,scalar* B,scalar* AB);/* AB*v=A*B*v*/
scalar* mv3d(scalar* M,scalar* V,scalar* MV); /* MV=M*V	*/

/* material */

unsigned char* create_mem_img(unsigned int width, unsigned int height);

GLuint mem_img2texture(unsigned char* data,unsigned int width, unsigned int height,int linear);
GLuint imgfile2texture(char const *filepath);
GLuint apply_texture(GLuint id);

/* camera */

enum OFFSET{VEC_X=0,VEC_Y=1<<2,VEC_Z=2<<2,VEC_T=3<<2,PROJECTION=1<<4,VIEW=2<<4,BIAS=3<<4, 	
		POS_H=4<<4,POS_V=(4<<4)+1,POS_DIST=(4<<4)+2,
		VEC_ORG=(4<<4)+(1<<2),VEC_DIR=(4<<4)+(2<<2),VEC_TEMP=(4<<4)+(3<<2)};  

typedef scalar* camera3d_t; 

camera3d_t create_camera3d(scalar dist);

camera3d_t move_camera(camera3d_t camera,scalar right, scalar up, scalar back);
camera3d_t rotate_camera(camera3d_t camera,scalar dh,scalar dv);
camera3d_t scale_camera(camera3d_t camera,scalar s);

camera3d_t set_camera_position(camera3d_t camera, scalar x, scalar y, scalar z);
camera3d_t resize_camera(camera3d_t camera, scalar w, scalar h);
/* http://blog.csdn.net/gnuser/article/details/5146598 */
camera3d_t set_camera_projection(camera3d_t camera,scalar near,scalar far,scalar fov,scalar wh);
camera3d_t set_camera_direction(camera3d_t camera, scalar x, scalar y, scalar z,scalar upx,scalar upy,scalar upz);
camera3d_t update_camera(camera3d_t camera);
		
camera3d_t camera_look(camera3d_t camera);
camera3d_t camera3d_xy2ray(camera3d_t camera, scalar x, scalar y,scalar* ray);

/* opengl setup*/
		
/* 2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768,65536 */
enum GL_OPTIONS{TEXTURE_2D=2,LIGHTING=4,CULL_FACE=8,BLEND=16,FILL=32,SMOOTH=64,FOG=128};
int init_opengl(void);
int set_viewport(int x,int y,int w, int h);
int apply_options(int options);
int set_bg_color(scalar r,scalar g, scalar b, scalar a);
int clear_buffers(void);

/* matrix */
scalar* push_matrix(scalar* matrix);
scalar* pop_matrix(scalar* matrix);

/* shader */

GLhandleARB compile_shader(const char* string,GLenum type);
GLhandleARB build_shader(const char* vert,const char* frag);
GLuint* create_shadowFBO(GLuint width,GLuint height);
GLhandleARB apply_shader(GLhandleARB shaderid);

/* rander FBO */

GLuint* create_shadowFBO(GLuint width,GLuint height);
int prepare_render_shadow(camera3d_t light,GLuint* shadowFBO);
int bind_shadow2shader(camera3d_t light,GLuint* shadowFBO,GLuint shader);
int prepare_render_normal(camera3d_t camera);

/* basic draw functions */

GLuint gen_list_begin();
GLuint gen_list_end();
GLuint call_list(GLuint id);

enum{POINTS,LINES,POLYGON,TRIANGLES,QUADS,LINE_STRIP,LINE_LOOP,TRIANGLE_STRIP,TRIANGLE_FAN,QUAD_STRIP};

int begin_draw(int type);
int end_draw(void);
int set_vertex(scalar x,scalar y,scalar z, scalar tx,scalar ty,scalar nx, scalar ny, scalar nz);
int set_vertex_v(scalar* V,scalar* N,scalar tx,scalar ty);

int register_light_pos(int id,scalar x,scalar y,scalar z,scalar w);




#endif



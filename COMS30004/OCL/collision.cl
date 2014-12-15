#pragma OPENCL EXTENSION cl_khr_fp64 : enable

#define NSPEEDS 9

/* struct to hold the parameter values */
//typedef struct {
//  int    nx;            /* no. of cells in x-direction */
//  int    ny;            /* no. of cells in y-direction */
//  int    maxIters;      /* no. of iterations */
//  int    reynolds_dim;  /* dimension for Reynolds number */
//  float density;       /* density per link */
//  float accel;         /* density redistribution */
//  float omega;         /* relaxation parameter */
//} t_param;

/* struct to hold the 'speed' values */
typedef struct {
  float speeds[NSPEEDS];
} t_speed;

// 1D kernel, run as ny * nx
__kernel void collision(const float omega, __global t_speed* cells, const __global t_speed* tmp_cells, const __global char* obstacles)
{
  //Mark obstacles as const or _constant?
  int kk;                         /* generic counters */
  const double c_sq = 1.0/3.0;  /* square of speed of sound */
  const double w0 = 4.0/9.0;    /* weighting factor */
  const double w1 = 1.0/9.0;    /* weighting factor */
  const double w2 = 1.0/36.0;   /* weighting factor */
  double u_x,u_y;               /* av. velocities in x and y directions */
  double u[NSPEEDS];            /* directional velocities */
  double d_equ[NSPEEDS];        /* equilibrium densities */
  double u_sq;                  /* squared velocity */
  double local_density;         /* sum of densities in a particular cell */

  /* loop over the cells in the grid
  ** NB the collision step is called after
  ** the propagate step and so values of interest
  ** are in the scratch-space grid */
  //for(curr_cell=0;curr_cell<cell_lim;++curr_cell) {
  const int curr_cell = get_global_id(0);
      if(obstacles[curr_cell]) {
	/* called after propagate, so taking values from scratch space
	** mirroring, and writing into main grid */
	cells[curr_cell].speeds[1] = tmp_cells[curr_cell].speeds[3];
	cells[curr_cell].speeds[2] = tmp_cells[curr_cell].speeds[4];
	cells[curr_cell].speeds[3] = tmp_cells[curr_cell].speeds[1];
	cells[curr_cell].speeds[4] = tmp_cells[curr_cell].speeds[2];
	cells[curr_cell].speeds[5] = tmp_cells[curr_cell].speeds[7];
	cells[curr_cell].speeds[6] = tmp_cells[curr_cell].speeds[8];
	cells[curr_cell].speeds[7] = tmp_cells[curr_cell].speeds[5];
	cells[curr_cell].speeds[8] = tmp_cells[curr_cell].speeds[6];
      } else {
	/* don't consider occupied cells */
	/* compute local density total */
	local_density = 0.0;
	#pragma unroll
	for(kk=0;kk<NSPEEDS;kk++) {
	  local_density += tmp_cells[curr_cell].speeds[kk];
	}

	/* compute x velocity component */
	u_x = (tmp_cells[curr_cell].speeds[1] + 
	       tmp_cells[curr_cell].speeds[5] + 
	       tmp_cells[curr_cell].speeds[8]
	       - (tmp_cells[curr_cell].speeds[3] + 
		  tmp_cells[curr_cell].speeds[6] + 
		  tmp_cells[curr_cell].speeds[7]))
	  / local_density;

	/* compute y velocity component */
	u_y = (tmp_cells[curr_cell].speeds[2] + 
	       tmp_cells[curr_cell].speeds[5] + 
	       tmp_cells[curr_cell].speeds[6]
	       - (tmp_cells[curr_cell].speeds[4] + 
		  tmp_cells[curr_cell].speeds[7] + 
		  tmp_cells[curr_cell].speeds[8]))
	  / local_density;

	/* velocity squared */ 
	u_sq = u_x * u_x + u_y * u_y;
	/* directional velocity components */
	u[1] =   u_x;        /* east */
	u[2] =         u_y;  /* north */
	u[3] = - u_x;        /* west */
	u[4] =       - u_y;  /* south */
	u[5] =   u_x + u_y;  /* north-east */
	u[6] = - u_x + u_y;  /* north-west */
	u[7] = - u_x - u_y;  /* south-west */
	u[8] =   u_x - u_y;  /* south-east */
	/* equilibrium densities */
	/* zero velocity density: weight w0 */
	d_equ[0] = w0 * local_density * (1.0 - u_sq / (2.0 * c_sq));
	/* axis speeds: weight w1 */
	d_equ[1] = w1 * local_density * (1.0 + u[1] / c_sq
					 + (u[1] * u[1]) / (2.0 * c_sq * c_sq)
					 - u_sq / (2.0 * c_sq));
	d_equ[2] = w1 * local_density * (1.0 + u[2] / c_sq
					 + (u[2] * u[2]) / (2.0 * c_sq * c_sq)
					 - u_sq / (2.0 * c_sq));
	d_equ[3] = w1 * local_density * (1.0 + u[3] / c_sq
					 + (u[3] * u[3]) / (2.0 * c_sq * c_sq)
					 - u_sq / (2.0 * c_sq));
	d_equ[4] = w1 * local_density * (1.0 + u[4] / c_sq
					 + (u[4] * u[4]) / (2.0 * c_sq * c_sq)
					 - u_sq / (2.0 * c_sq));
	/* diagonal speeds: weight w2 */
	d_equ[5] = w2 * local_density * (1.0 + u[5] / c_sq
					 + (u[5] * u[5]) / (2.0 * c_sq * c_sq)
					 - u_sq / (2.0 * c_sq));
	d_equ[6] = w2 * local_density * (1.0 + u[6] / c_sq
					 + (u[6] * u[6]) / (2.0 * c_sq * c_sq)
					 - u_sq / (2.0 * c_sq));
	d_equ[7] = w2 * local_density * (1.0 + u[7] / c_sq
					 + (u[7] * u[7]) / (2.0 * c_sq * c_sq)
					 - u_sq / (2.0 * c_sq));
	d_equ[8] = w2 * local_density * (1.0 + u[8] / c_sq
					 + (u[8] * u[8]) / (2.0 * c_sq * c_sq)
					 - u_sq / (2.0 * c_sq));
	/* relaxation step */
	#pragma unroll
	for(kk=0;kk<NSPEEDS;kk++) {
	  cells[curr_cell].speeds[kk] = (tmp_cells[curr_cell].speeds[kk]
						 + omega * 
						 (d_equ[kk] - tmp_cells[curr_cell].speeds[kk]));
	}
    
  }
}

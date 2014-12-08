#define NSPEEDS 9

/* struct to hold the parameter values */
typedef struct {
  int    nx;            /* no. of cells in x-direction */
  int    ny;            /* no. of cells in y-direction */
  int    maxIters;      /* no. of iterations */
  int    reynolds_dim;  /* dimension for Reynolds number */
  float density;       /* density per link */
  float accel;         /* density redistribution */
  float omega;         /* relaxation parameter */
} t_param;

/* struct to hold the 'speed' values */
typedef struct {
  float speeds[NSPEEDS];
} t_speed;

__kernel void av_velocity(const t_param params, __global t_speed* cells, __global int* obstacles, __global float* tot_u, __global int* tot_cells, const int iter)
{
  int    kk,curr_cell;       /* generic counters */
  float local_density;  /* total density in cell */
  float u_x;            /* x-component of velocity for current cell */
  float u_y;            /* y-component of velocity for current cell */

  const int cell_lim = (params.ny * params.nx);

  /* initialise */
  tot_u[iter] = 0.0;

  /* loop over all non-blocked cells */
  for(curr_cell=0;curr_cell<cell_lim;++curr_cell) {
      /* ignore occupied cells */
      if(!obstacles[curr_cell]) {
	/* local density total */
	local_density = 0.0;
	for(kk=0;kk<NSPEEDS;kk++) {
	  local_density += cells[curr_cell].speeds[kk];
	}
	/* x-component of velocity */
	u_x = (cells[curr_cell].speeds[1] + 
		    cells[curr_cell].speeds[5] + 
		    cells[curr_cell].speeds[8]
		    - (cells[curr_cell].speeds[3] + 
		       cells[curr_cell].speeds[6] + 
		       cells[curr_cell].speeds[7])) / 
	  local_density;
	/* compute y velocity component */
	u_y = (cells[curr_cell].speeds[2] + 
		    cells[curr_cell].speeds[5] + 
		    cells[curr_cell].speeds[6]
		    - (cells[curr_cell].speeds[4] + 
		       cells[curr_cell].speeds[7] + 
		       cells[curr_cell].speeds[8])) /
	  local_density;
	/* accumulate the norm of x- and y- velocity components */
	tot_u[iter] += sqrt((u_x * u_x) + (u_y * u_y));
	/* increase counter of inspected cells */
	tot_cells[iter] += 1;
    }
  }
}

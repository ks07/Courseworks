#define NSPEEDS 9

__kernel void collision(const float omega, __global float* cells, const __global float* tmp_cells, const __global char* obstacles) {
  int kk;                         /* generic counters */
  const float c_sq = 1.0/3.0;  /* square of speed of sound */
  const float w0 = 4.0/9.0;    /* weighting factor */
  const float w1 = 1.0/9.0;    /* weighting factor */
  const float w2 = 1.0/36.0;   /* weighting factor */
  float u_x,u_y;               /* av. velocities in x and y directions */
  float u[NSPEEDS];            /* directional velocities */
  float d_equ[NSPEEDS];        /* equilibrium densities */
  float u_sq;                  /* squared velocity */
  float local_density;         /* sum of densities in a particular cell */

  /* loop over the cells in the grid
  ** NB the collision step is called after
  ** the propagate step and so values of interest
  ** are in the scratch-space grid */
  const unsigned int curr_cell = get_global_id(0);

  // Read from tmp_cells into private before the conditional, as both branches need it.
  const float tmp_speeds[NSPEEDS] = {
    tmp_cells[0*get_global_size(0) + curr_cell],
    tmp_cells[1*get_global_size(0) + curr_cell],
    tmp_cells[2*get_global_size(0) + curr_cell],
    tmp_cells[3*get_global_size(0) + curr_cell],
    tmp_cells[4*get_global_size(0) + curr_cell],
    tmp_cells[5*get_global_size(0) + curr_cell],
    tmp_cells[6*get_global_size(0) + curr_cell],
    tmp_cells[7*get_global_size(0) + curr_cell],
    tmp_cells[8*get_global_size(0) + curr_cell]
  };

  if(obstacles[curr_cell]) {
    /* called after propagate, so taking values from scratch space
    ** mirroring, and writing into main grid */
    cells[1*get_global_size(0) + curr_cell] = tmp_speeds[3];
    cells[2*get_global_size(0) + curr_cell] = tmp_speeds[4];
    cells[3*get_global_size(0) + curr_cell] = tmp_speeds[1];
    cells[4*get_global_size(0) + curr_cell] = tmp_speeds[2];
    cells[5*get_global_size(0) + curr_cell] = tmp_speeds[7];
    cells[6*get_global_size(0) + curr_cell] = tmp_speeds[8];
    cells[7*get_global_size(0) + curr_cell] = tmp_speeds[5];
    cells[8*get_global_size(0) + curr_cell] = tmp_speeds[6];
  } else {
    /* don't consider occupied cells */
    /* compute local density total */
    local_density = 0.0;
#pragma unroll 9
    for(kk=0;kk<NSPEEDS;kk++) {
      local_density += tmp_speeds[kk];
    }

    /* compute x velocity component */
    u_x = (tmp_speeds[1] + 
	   tmp_speeds[5] + 
	   tmp_speeds[8]
	   - (tmp_speeds[3] + 
	      tmp_speeds[6] + 
	      tmp_speeds[7]))
      / local_density;

    /* compute y velocity component */
    u_y = (tmp_speeds[2] + 
	   tmp_speeds[5] + 
	   tmp_speeds[6]
	   - (tmp_speeds[4] + 
	      tmp_speeds[7] + 
	      tmp_speeds[8]))
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
#pragma unroll 9
    for(kk=0;kk<NSPEEDS;kk++) {
      cells[kk*get_global_size(0) + curr_cell] = (tmp_speeds[kk] + omega * (d_equ[kk] - tmp_speeds[kk]));
    }
  }
}

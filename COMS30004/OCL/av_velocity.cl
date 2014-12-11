#define NSPEEDS 9

/* struct to hold the 'speed' values */
typedef struct {
  float speeds[NSPEEDS];
} t_speed;

void reduce(__local float*, __global float*);

__kernel void av_velocity(const unsigned int global_lim, const unsigned int unit_len, const __global t_speed* cells, const __global int* obstacles, __local float* l_tot_u, __global float* round_tot_u)
{
  int   kk,curr_cell;   /* generic counters */
  float local_density;  /* total density in cell */
  float u_x;            /* x-component of velocity for current cell */
  float u_y;            /* y-component of velocity for current cell */

  // Reduction specific vars. Taken from Exercise09, HandsOnOpenCL
  float l_u = 0.0; // Private accumulator
  int work_group_size = get_local_size(0); // The number of elements belonging to each work group.
  int local_id = get_local_id(0); // Our rank inside the work group. We can only synchronise within work groups.
  int group_id = get_group_id(0); // Our workgroup's id.

  // Calculate our starting position from our group's position and our local id.
  int istart = (group_id * work_group_size + local_id)  * unit_len;
  int iend = istart + unit_len;

  for (curr_cell = istart; curr_cell < iend; curr_cell++) {
    // Use the global size to jump ahead to form the tree structure of reduction.
    // For all the elements in this work
    /* ignore occupied cells */
    if(curr_cell < global_lim && !obstacles[curr_cell]) {
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
      l_u += sqrt((u_x * u_x) + (u_y * u_y));
    }
  }

  // Save the work unit's sum into our work group's local memory
  l_tot_u[local_id] = l_u;

  // Wait for all units to save their value.
  barrier(CLK_LOCAL_MEM_FENCE);

  // Let unit 0 do the reduction into global.
  reduce(l_tot_u, round_tot_u);

  // Need to write to result array, outside of kernel?
}

void reduce(__local float* local_sums, __global float* partial_sums) {
  int num_wrk_items = get_local_size(0);
  int local_id     = get_local_id(0);
  int group_id     = get_group_id(0);

  float sum;
  int i;

  if (local_id == 0) {
    sum = 0.0f;

    for (i=0; i<num_wrk_items; i++) {
      sum += local_sums[i];
    }

    partial_sums[group_id] = sum;
  }
}

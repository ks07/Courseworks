#define NSPEEDS 9

void reduce(const __local float*, __global float*, const unsigned int);

__kernel void av_velocity(const unsigned int global_lim, const unsigned int unit_len, const __global float* cells, const __global char* obstacles, __local float* l_tot_u, __global float* round_tot_u, const unsigned int round)
{
  unsigned int kk,curr_cell; /* generic counters */
  float local_density;       /* total density in cell */
  float u_x;                 /* x-component of velocity for current cell */
  float u_y;                 /* y-component of velocity for current cell */

  // Reduction specific vars. Taken from Exercise09, HandsOnOpenCL
  float l_u = 0.0; // Private accumulator
  const int worker_count = get_local_size(0); // The number of workers in each work group.
  const int group_item_total = worker_count * unit_len;
  const int local_id = get_local_id(0); // Our rank inside the work group. We can only synchronise within work groups.
  const int group_id = get_group_id(0); // Our workgroup's id.

  // Calculate our starting position from our group's position and our local id.
  const int istart = (group_item_total * group_id) + local_id;
  const int istep = worker_count;
  const int iend = istart + (istep * unit_len);

  for (curr_cell = istart; curr_cell < iend; curr_cell += istep) {
    // Use the global size to jump ahead to form the tree structure of reduction.
    // For all the elements in this work
    /* ignore occupied cells */
    if(curr_cell < global_lim && !obstacles[curr_cell]) {
      /* local density total */
      local_density = 0.0;
#pragma unroll 9
      for(kk=0;kk<NSPEEDS;kk++) {
  	local_density += cells[kk*global_lim + curr_cell];
      }
      /* x-component of velocity */
      u_x = (cells[1*global_lim + curr_cell] +
  	     cells[5*global_lim + curr_cell] +
  	     cells[8*global_lim + curr_cell]
  	     - (cells[3*global_lim + curr_cell] +
  		cells[6*global_lim + curr_cell] +
  		cells[7*global_lim + curr_cell])) /
  	local_density;
      /* compute y velocity component */
      u_y = (cells[2*global_lim + curr_cell] +
  	     cells[5*global_lim + curr_cell] +
  	     cells[6*global_lim + curr_cell]
  	     - (cells[4*global_lim + curr_cell] +
  		cells[7*global_lim + curr_cell] +
  		cells[8*global_lim + curr_cell])) /
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
  reduce(l_tot_u, round_tot_u, round);
}

void reduce(const __local float* local_sums, __global float* partial_sums, const unsigned int round) {
  const unsigned int num_wrk_items = get_local_size(0);
  const unsigned int local_id      = get_local_id(0);
  const unsigned int group_id      = get_group_id(0);
  const unsigned int ps_offset     = round * get_num_groups(0);

  float sum = 0.0f;

  if (local_id == 0) {
    for (int i=0; i<num_wrk_items; i++) {
      sum += local_sums[i];
    }

    partial_sums[ps_offset + group_id] = sum;
  }
}

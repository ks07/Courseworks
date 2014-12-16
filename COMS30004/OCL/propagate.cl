__kernel void propagate(const __global float* cells, __global float* tmp_cells, const __global unsigned int* adjacency)
{
  const unsigned int curr_cell_speed = get_global_id(0);
  /* propagate densities to neighbouring cells, following
  ** appropriate directions of travel and writing into
  ** scratch space grid */
  tmp_cells[curr_cell_speed] = cells[ adjacency[curr_cell_speed] ];
}

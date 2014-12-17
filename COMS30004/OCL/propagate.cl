__kernel void propagate(const __global float* cells, __global float* tmp_cells, const __global unsigned int* adjacency) {
  const unsigned int curr_cell = get_global_id(0);
  /* propagate densities to neighbouring cells, following
  ** appropriate directions of travel and writing into
  ** scratch space grid */
  tmp_cells[curr_cell] = cells[curr_cell];                                                          /* central cell, */
  /* no movement */
  tmp_cells[1*get_global_size(0) + curr_cell] = cells[adjacency[1*get_global_size(0) + curr_cell]]; /* east */
  tmp_cells[2*get_global_size(0) + curr_cell] = cells[adjacency[2*get_global_size(0) + curr_cell]]; /* north */
  tmp_cells[3*get_global_size(0) + curr_cell] = cells[adjacency[3*get_global_size(0) + curr_cell]]; /* west */
  tmp_cells[4*get_global_size(0) + curr_cell] = cells[adjacency[4*get_global_size(0) + curr_cell]]; /* south */
  tmp_cells[5*get_global_size(0) + curr_cell] = cells[adjacency[5*get_global_size(0) + curr_cell]]; /* north-east */
  tmp_cells[6*get_global_size(0) + curr_cell] = cells[adjacency[6*get_global_size(0) + curr_cell]]; /* north-west */
  tmp_cells[7*get_global_size(0) + curr_cell] = cells[adjacency[7*get_global_size(0) + curr_cell]]; /* south-west */
  tmp_cells[8*get_global_size(0) + curr_cell] = cells[adjacency[8*get_global_size(0) + curr_cell]]; /* south-east */
}

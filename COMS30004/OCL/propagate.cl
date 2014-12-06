__kernel void propagate(const t_param params, __global t_speed* cells, __global t_speed* tmp_cells, __global t_adjacency* adjacency)
{
  // Constant adjacency... or no adjacency?
  int curr_cell; // Stop re-calculating the array index repeatedly.
  //  const int cell_lim = (params.ny * params.nx);

  /* loop over _all_ cells */
  //for(curr_cell=0;curr_cell<cell_lim;++curr_cell) {
  curr_cell = get_global_id(0);
    /* propagate densities to neighbouring cells, following
    ** appropriate directions of travel and writing into
    ** scratch space grid */
    tmp_cells[curr_cell].speeds[0] = cells[curr_cell].speeds[0];                     /* central cell, */
                                                                                     /* no movement */
    tmp_cells[adjacency[curr_cell].index[1]].speeds[1] = cells[curr_cell].speeds[1]; /* east */
    tmp_cells[adjacency[curr_cell].index[2]].speeds[2] = cells[curr_cell].speeds[2]; /* north */
    tmp_cells[adjacency[curr_cell].index[3]].speeds[3] = cells[curr_cell].speeds[3]; /* west */
    tmp_cells[adjacency[curr_cell].index[4]].speeds[4] = cells[curr_cell].speeds[4]; /* south */
    tmp_cells[adjacency[curr_cell].index[5]].speeds[5] = cells[curr_cell].speeds[5]; /* north-east */
    tmp_cells[adjacency[curr_cell].index[6]].speeds[6] = cells[curr_cell].speeds[6]; /* north-west */
    tmp_cells[adjacency[curr_cell].index[7]].speeds[7] = cells[curr_cell].speeds[7]; /* south-west */
    tmp_cells[adjacency[curr_cell].index[8]].speeds[8] = cells[curr_cell].speeds[8]; /* south-east */
    //}
}

#define NSPEEDS 9

/* struct to hold the 'speed' values */
/*  typedef struct { */
/*   float speeds[NSPEEDS]; */
/* } t_speed; */

// struct to hold adjacency indices
/* typedef struct { */
/*   unsigned int index[NSPEEDS]; */
/* } t_adjacency; */

__kernel void propagate(const __global float* cells, __global float* tmp_cells, const __global unsigned int* adjacency)
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
    tmp_cells[curr_cell] = cells[curr_cell];                     /* central cell, */
                                                                                     /* no movement */
    tmp_cells[adjacency[1*get_global_size(0) + curr_cell]] = cells[1*get_global_size(0) + curr_cell]; /* east */
    tmp_cells[adjacency[2*get_global_size(0) + curr_cell]] = cells[2*get_global_size(0) + curr_cell]; /* north */
    tmp_cells[adjacency[3*get_global_size(0) + curr_cell]] = cells[3*get_global_size(0) + curr_cell]; /* west */
    tmp_cells[adjacency[4*get_global_size(0) + curr_cell]] = cells[4*get_global_size(0) + curr_cell]; /* south */
    tmp_cells[adjacency[5*get_global_size(0) + curr_cell]] = cells[5*get_global_size(0) + curr_cell]; /* north-east */
    tmp_cells[adjacency[6*get_global_size(0) + curr_cell]] = cells[6*get_global_size(0) + curr_cell]; /* north-west */
    tmp_cells[adjacency[7*get_global_size(0) + curr_cell]] = cells[7*get_global_size(0) + curr_cell]; /* south-west */
    tmp_cells[adjacency[8*get_global_size(0) + curr_cell]] = cells[8*get_global_size(0) + curr_cell]; /* south-east */
}

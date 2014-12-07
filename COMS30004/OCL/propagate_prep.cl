__kernel void propagate_prep(const t_param params, __global t_adjacency* adjacency)
{
  // If we move adjacency to constant, then this kernel is unnecessary
  int ii,jj;            /* generic counters */
  int x_e,x_w,y_n,y_s;  /* indices of neighbouring cells */

  /* loop over _all_ cells */
  //for(ii=0;ii<params.ny;ii++) {
  //for(jj=0;jj<params.nx;jj++) {
  ii = get_global_id(0);
  jj = geT_global_id(1);
      /* determine indices of axis-direction neighbours
      ** respecting periodic boundary conditions (wrap around) */
      y_n = (ii + 1) % params.ny;
      x_e = (jj + 1) % params.nx;
      y_s = (ii == 0) ? (ii + params.ny - 1) : (ii - 1);
      x_w = (jj == 0) ? (jj + params.nx - 1) : (jj - 1);
      //Pre-calculate the adjacent cells to propagate to.
      //adjacency[ii*params.nx + jj].index[0] = ii * params.nx + jj; // Centre, ignore
      adjacency[ii*params.nx + jj].index[1] = ii * params.nx + x_e; // N
      adjacency[ii*params.nx + jj].index[2] = y_n * params.nx + jj; // E
      adjacency[ii*params.nx + jj].index[3] = ii * params.nx + x_w; // W
      adjacency[ii*params.nx + jj].index[4] = y_s * params.nx + jj; // S
      adjacency[ii*params.nx + jj].index[5] = y_n * params.nx + x_e; // NE
      adjacency[ii*params.nx + jj].index[6] = y_n * params.nx + x_w; // NW
      adjacency[ii*params.nx + jj].index[7] = y_s * params.nx + x_w; // SW
      adjacency[ii*params.nx + jj].index[8] = y_s * params.nx + x_e; // SE
      //}
      //}
}

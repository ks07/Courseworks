__kernel void propagate_prep(__global unsigned int* adjacency) {
  const unsigned int ny = get_global_size(0);
  const unsigned int nx = get_global_size(1);
  const unsigned int ii = get_global_id(0);
  const unsigned int jj = get_global_id(1);

  /* determine indices of axis-direction neighbours
  ** respecting periodic boundary conditions (wrap around) */
  const unsigned int y_s = (ii + 1) % ny;
  const unsigned int x_w = (jj + 1) % nx;
  const unsigned int y_n = (ii == 0) ? (ii + ny - 1) : (ii - 1);
  const unsigned int x_e = (jj == 0) ? (jj + nx - 1) : (jj - 1);

  //Pre-calculate the adjacent cells to propagate to.
  adjacency[0*nx*ny + ii*nx + jj] = 0*nx*ny + ii  * nx + jj; // Centre, ignore
  adjacency[1*nx*ny + ii*nx + jj] = 1*nx*ny + ii  * nx + x_e; // E
  adjacency[2*nx*ny + ii*nx + jj] = 2*nx*ny + y_n * nx + jj;  // N
  adjacency[3*nx*ny + ii*nx + jj] = 3*nx*ny + ii  * nx + x_w; // W
  adjacency[4*nx*ny + ii*nx + jj] = 4*nx*ny + y_s * nx + jj;  // S
  adjacency[5*nx*ny + ii*nx + jj] = 5*nx*ny + y_n * nx + x_e; // NE
  adjacency[6*nx*ny + ii*nx + jj] = 6*nx*ny + y_n * nx + x_w; // NW
  adjacency[7*nx*ny + ii*nx + jj] = 7*nx*ny + y_s * nx + x_w; // SW
  adjacency[8*nx*ny + ii*nx + jj] = 8*nx*ny + y_s * nx + x_e; // SE
}

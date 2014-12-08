#define NSPEEDS 9

// struct to hold adjacency indices
typedef struct {
  unsigned int index[NSPEEDS];
} t_adjacency;

// TODO: Use cl_ types in host code to avoid size issues!

__kernel void propagate_prep(__global t_adjacency* adjacency)
{
  // If we move adjacency to constant, then this kernel is unnecessary
  int ii,jj;            /* generic counters */
  int x_e,x_w,y_n,y_s;  /* indices of neighbouring cells */
  const int nx = get_global_size(0); // Avoid needing to import params
  const int ny = get_global_size(1);

  /* loop over _all_ cells */
  //for(ii=0;ii<params.ny;ii++) {
  //for(jj=0;jj<params.nx;jj++) {
  ii = get_global_id(0);
  jj = get_global_id(1);
      /* determine indices of axis-direction neighbours
      ** respecting periodic boundary conditions (wrap around) */
      y_n = (ii + 1) % ny;
      x_e = (jj + 1) % nx;
      y_s = (ii == 0) ? (ii + ny - 1) : (ii - 1);
      x_w = (jj == 0) ? (jj + nx - 1) : (jj - 1);
      //Pre-calculate the adjacent cells to propagate to.
      //adjacency[ii*params.nx + jj].index[0] = ii * params.nx + jj; // Centre, ignore
      adjacency[ii*nx + jj].index[1] = ii  * nx + x_e; // N
      adjacency[ii*nx + jj].index[2] = y_n * nx + jj;  // E
      adjacency[ii*nx + jj].index[3] = ii  * nx + x_w; // W
      adjacency[ii*nx + jj].index[4] = y_s * nx + jj;  // S
      adjacency[ii*nx + jj].index[5] = y_n * nx + x_e; // NE
      adjacency[ii*nx + jj].index[6] = y_n * nx + x_w; // NW
      adjacency[ii*nx + jj].index[7] = y_s * nx + x_w; // SW
      adjacency[ii*nx + jj].index[8] = y_s * nx + x_e; // SE
      //}
      //}
}

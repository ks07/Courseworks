#define NSPEEDS 9

/* struct to hold the 'speed' values */
typedef struct {
  float speeds[NSPEEDS];
} t_speed;

__kernel void propagate(const __global t_speed* cells, __global t_speed* tmp_cells)
{
  unsigned int ii,jj;            /* generic counters */
  unsigned int x_e,x_w,y_n,y_s;  /* indices of neighbouring cells */
  
  /* loop over _all_ cells */
  //for(ii=0;ii<params.ny;ii++) {
  //for(jj=0;jj<params.nx;jj++) {
  const unsigned int ny = get_global_size(0); // Avoid needing to import params
  const unsigned int nx = get_global_size(1);
  ii = get_global_id(0);
  jj = get_global_id(1);
  /* determine indices of axis-direction neighbours
  ** respecting periodic boundary conditions (wrap around) */
  y_n = (ii == ny - 1) ? 0 : ii+1;
  x_e = (jj == nx - 1) ? 0 : jj+1;
  //y_s = (ii == 0) ? (ii + ny - 1) : (ii - 1);
  y_s = min(ny - 1, ii - 1);
  //x_w = (jj == 0) ? (jj + nx - 1) : (jj - 1);
  x_w = min(nx - 1, jj - 1);
  /* propagate densities to neighbouring cells, following
  ** appropriate directions of travel and writing into
  ** scratch space grid */
  tmp_cells[ii *nx + jj].speeds[0]  = cells[ii*nx + jj].speeds[0]; /* central cell */
  tmp_cells[ii *nx + x_e].speeds[1] = cells[ii*nx + jj].speeds[1]; /* east */
  tmp_cells[y_n*nx + jj].speeds[2]  = cells[ii*nx + jj].speeds[2]; /* north */
  tmp_cells[ii *nx + x_w].speeds[3] = cells[ii*nx + jj].speeds[3]; /* west */
  tmp_cells[y_s*nx + jj].speeds[4]  = cells[ii*nx + jj].speeds[4]; /* south */
  tmp_cells[y_n*nx + x_e].speeds[5] = cells[ii*nx + jj].speeds[5]; /* north-east */
  tmp_cells[y_n*nx + x_w].speeds[6] = cells[ii*nx + jj].speeds[6]; /* north-west */
  tmp_cells[y_s*nx + x_w].speeds[7] = cells[ii*nx + jj].speeds[7]; /* south-west */      
  tmp_cells[y_s*nx + x_e].speeds[8] = cells[ii*nx + jj].speeds[8]; /* south-east */
}

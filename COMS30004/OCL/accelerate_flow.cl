/* struct to hold the parameter values */
typedef struct {
  int    nx;            /* no. of cells in x-direction */
  int    ny;            /* no. of cells in y-direction */
  int    maxIters;      /* no. of iterations */
  int    reynolds_dim;  /* dimension for Reynolds number */
  float density;       /* density per link */
  float accel;         /* density redistribution */
  float omega;         /* relaxation parameter */
} t_param;

__kernel void accelerate_flow(const t_param params, __global float* cells, const __global char* obstacles) {
  /* compute weighting factors */
  const float w1 = params.density * params.accel / 9.0;
  const float w2 = params.density * params.accel / 36.0;

  /* modify the 2nd row of the grid */
  const unsigned int ii = params.ny - 2;
  const unsigned int jj = get_global_id(0);

  /* if the cell is not occupied and
  ** we don't send a density negative */
  if( !obstacles[ii*params.nx + jj] && 
      (cells[3*params.nx*params.ny + ii*params.nx + jj] - w1) > 0.0 &&
      (cells[6*params.nx*params.ny + ii*params.nx + jj] - w2) > 0.0 &&
      (cells[7*params.nx*params.ny + ii*params.nx + jj] - w2) > 0.0 ) {
    /* increase 'east-side' densities */
    cells[1*params.nx*params.ny + ii*params.nx + jj] += w1;
    cells[5*params.nx*params.ny + ii*params.nx + jj] += w2;
    cells[8*params.nx*params.ny + ii*params.nx + jj] += w2;
    /* decrease 'west-side' densities */
    cells[3*params.nx*params.ny + ii*params.nx + jj] -= w1;
    cells[6*params.nx*params.ny + ii*params.nx + jj] -= w2;
    cells[7*params.nx*params.ny + ii*params.nx + jj] -= w2;
  }
}

/*
** Code to implement a d2q9-bgk lattice boltzmann scheme.
** 'd2' inidates a 2-dimensional grid, and
** 'q9' indicates 9 velocities per grid cell.
** 'bgk' refers to the Bhatnagar-Gross-Krook collision step.
**
** The 'speeds' in each cell are numbered as follows:
**
** 6 2 5
**  \|/
** 3-0-1
**  /|\
** 7 4 8
**
** A 2D grid:
**
**           cols
**       --- --- ---
**      | D | E | F |
** rows  --- --- ---
**      | A | B | C |
**       --- --- ---
**
** 'unwrapped' in row major order to give a 1D array:
**
**  --- --- --- --- --- ---
** | A | B | C | D | E | F |
**  --- --- --- --- --- ---
**
** Grid indicies are:
**
**          ny
**          ^       cols(jj)
**          |  ----- ----- -----
**          | | ... | ... | etc |
**          |  ----- ----- -----
** rows(ii) | | 1,0 | 1,1 | 1,2 |
**          |  ----- ----- -----
**          | | 0,0 | 0,1 | 0,2 |
**          |  ----- ----- -----
**          ----------------------> nx
**
** Note the names of the input parameter and obstacle files
** are passed on the command line, e.g.:
**
**   d2q9-bgk.exe input.params obstacles.dat
**
** Be sure to adjust the grid dimensions in the parameter file
** if you choose a different obstacle file.
*/

#include<math.h>
#include<stdio.h>
#include<stdlib.h>
#include<time.h>
#include<sys/time.h>
#include<sys/resource.h>
#include "mpi.h"

#define NSPEEDS         9
#define FINALSTATEFILE  "final_state.dat"
#define AVVELSFILE      "av_vels.dat"

// Add an easy way to switch between single and double precision math.
#ifdef SINGLE_PRECISION
typedef float my_float;
#define my_sqrt sqrtf
#define MY_FLOAT_PATTERN "%f\n"
#define MY_MPI_FLOAT MPI_FLOAT
#else
typedef double my_float;
#define my_sqrt sqrt
#define MY_FLOAT_PATTERN "%lf\n"
#define MY_MPI_FLOAT MPI_DOUBLE
#endif

// If true, slices should not communicate in this direction, as they are alone in this axis.
#define SINGLE_SLICE_Y 0
#define SINGLE_SLICE_X 0

// If true, we should run an extra step to store an adjacency mapping for propagate.
// This should become less efficient if both SINGLE_SLICE values are set false, or if we use
// very small slice sizes.
#define USE_PROPAGATION_CACHE 0

/* struct to hold the parameter values */
typedef struct {
  int    nx;            /* no. of cells in x-direction */
  int    ny;            /* no. of cells in y-direction */
  int    maxIters;      /* no. of iterations */
  int    reynolds_dim;  /* dimension for Reynolds number */
  my_float density;       /* density per link */
  my_float accel;         /* density redistribution */
  my_float omega;         /* relaxation parameter */
  // MPI specific extensions to hold info about the current slice.
  int size; // Number of slices.
  int rank; // Index of the current slice.
  int rank_north; // Index of the slice to the north.
  int rank_south; // Index of the slice to the south.
  int rank_east;
  int rank_west;
  int rank_nw, rank_ne, rank_sw, rank_se;
  int slice_len; // Size of the current slice.
  int slice_buff_len; // Size of the slice buffer, including overlap for halo.
  int slice_inner_start; // Local index of the first non-buffer cell.
  int slice_inner_end; // Local index of the last non-buffer cell.
  // Offset for nx and ny is going to be 1, as we only need a single cell border for exchange.
  int slice_nx; // Number of cells in the x direction in slice (inner).
  int slice_ny; // Number of cells in the y direction in slice (inner).
  int slice_global_xs; // The global minimum x coordinate of the current slice.
  int slice_global_ys; // The global minimum y coordinate of the current slice.
  int slice_global_xe; // The global maximum x coordinate of the current slice.
  int slice_global_ye; // The global maximum y coordinate of the current slice.
} t_param;

/* struct to hold the 'speed' values */
typedef struct {
  my_float speeds[NSPEEDS];
} t_speed;

// struct to hold adjacency indices
typedef struct {
  unsigned int index[NSPEEDS];
} t_adjacency;

enum boolean { FALSE, TRUE };

/*
** function prototypes
*/

/* load params, allocate memory, load obstacles & initialise fluid particle densities */
int initialise(const char* paramfile, const char* obstaclefile,
	       t_param* params, t_speed** cells_ptr, t_speed** tmp_cells_ptr, 
	       int** obstacles_ptr, my_float** av_vels_ptr, t_adjacency** adjacency);

/* 
** The main calculation methods.
** timestep calls, in order, the functions:
** accelerate_flow(), propagate(), rebound() & collision()
*/
int timestep(const t_param params, t_speed* cells, t_speed* tmp_cells, int* obstacles, t_adjacency* adjacency, my_float* sendbuf, my_float* recvbuf);
int accelerate_flow(const t_param params, t_speed* cells, int* obstacles);
int propagate_prep(const t_param params, t_adjacency* adjacency);
int propagate(const t_param params, t_speed* cells, t_speed* tmp_cells, t_adjacency* adjacency);
int collision(const t_param params, t_speed* cells, t_speed* tmp_cells, int* obstacles);
int write_values(const t_param params, t_speed* cells, int* obstacles, my_float* av_vels);

/* finalise, including freeing up allocated memory */
int finalise(const t_param* params, t_speed** cells_ptr, t_speed** tmp_cells_ptr,
	     int** obstacles_ptr, my_float** av_vels_ptr, t_adjacency** adjacency);

/* Sum all the densities in the grid.
** The total should remain constant from one timestep to the next. */
my_float total_density(const t_param params, t_speed* cells);

/* compute average velocity */
my_float av_velocity(const t_param params, t_speed* cells, int* obstacles);

/* calculate Reynolds number */
my_float calc_reynolds(const t_param params, const my_float av_vel);

/* utility functions */
void die(const char* message, const int line, const char *file);
void usage(const char* exe);
int within_slice_c(const t_param params, const int jj, const int ii);
int within_slice(const t_param params, const int index);
void pack_row(my_float* packed, const int start, const int interval, const int count, t_speed* cells);
void unpack_row(my_float* packed, const int start, const int interval, const int count, t_speed* cells, int sixtwofive);
void unpack_col(my_float* packed, const int start, const int interval, const int count, t_speed* cells, int fiveoneeight);
void pobs(const t_param params, int* obstacles);
void print_grid(const t_param params, t_speed* cells);
void print_row(const int rank, const int start, const int count, t_speed* cells);

/*
** main program:
** initialise, timestep loop, finalise
*/
int main(int argc, char* argv[])
{
  char*    paramfile = NULL;     /* name of the input parameter file */
  char*    obstaclefile = NULL;  /* name of a the input obstacle file */
  t_param  params;               /* struct to hold parameter values */
  t_speed* cells     = NULL;     /* grid containing fluid densities */
  t_speed* tmp_cells = NULL;     /* scratch space */
  int*     obstacles = NULL;     /* grid indicating which cells are blocked */
  my_float*  av_vels   = NULL;   /* a record of the av. velocity computed for each timestep */
  int      ii;                   /* generic counter */
  struct timeval timstr;         /* structure to hold elapsed time */
  struct rusage ru;              /* structure to hold CPU time--system and user */
  double tic,toc;                /* floating point numbers to calculate elapsed wallclock time */
  double usrtim;                 /* floating point number to record elapsed user CPU time */
  double systim;                 /* floating point number to record elapsed system CPU time */
  t_adjacency* adjacency = NULL; /* store adjacency for each cell in each direction for propagate. */
  my_float* sendbuf; // Send buffer, to be packed.
  my_float* recvbuf; // Recv buffer, to be unpacked.

  /* parse the command line */
  if(argc != 3) {
    usage(argv[0]);
  }
  else{
    // Init MPI, startup processes. Blocks until all ready.
    MPI_Init( &argc, &argv );

    // Get size and rank of the current process.
    MPI_Comm_size( MPI_COMM_WORLD, &(params.size) );
    MPI_Comm_rank( MPI_COMM_WORLD, &(params.rank) );

    paramfile = argv[1];
    obstaclefile = argv[2];
  }

  /* initialise our data structures and load values from file */
  initialise(paramfile, obstaclefile, &params, &cells, &tmp_cells, &obstacles, &av_vels, &adjacency);

  /* if (params.rank == 62 || params.rank == 63) { */
  /*   printf("r%d has sny: %d ys %d ye %d\n",params.rank,params.slice_ny,params.slice_global_ys,params.slice_global_ye); */
  /* } */
  /* while(1) {} */

  // Initialise the send and receive buffers.
  const int send_len = (((params.slice_ny > params.slice_nx) ? params.slice_ny : params.slice_nx) + 2) * NSPEEDS; // The length of the buffer needed to send the cells.
  sendbuf = malloc(sizeof(my_float) * send_len);
  recvbuf = malloc(sizeof(my_float) * send_len);

  // Synchronise all processes before we enter the simulation loop. Not really necessary...
  MPI_Barrier(MPI_COMM_WORLD);

  /* iterate for maxIters timesteps */
  gettimeofday(&timstr,NULL);
  tic=timstr.tv_sec+(timstr.tv_usec/1000000.0);

  // Can we do this outside the timing? Probably not!
#if USE_PROPAGATION_CACHE
  propagate_prep(params, adjacency);
#endif

  for (ii=0;ii<params.maxIters;ii++) {
    timestep(params,cells,tmp_cells,obstacles,adjacency,sendbuf,recvbuf);
    av_vels[ii] = av_velocity(params,cells,obstacles); // TODO: Only for rank 0?
#ifdef DEBUG
    printf("==timestep: %d==\n",ii);
    printf("av velocity: %.12E\n",av_vels[ii]);
    printf("tot density: %.12E\n",total_density(params,cells));
#endif
  }
  gettimeofday(&timstr,NULL);
  toc=timstr.tv_sec+(timstr.tv_usec/1000000.0);
  getrusage(RUSAGE_SELF, &ru);
  timstr=ru.ru_utime;        
  usrtim=timstr.tv_sec+(timstr.tv_usec/1000000.0);
  timstr=ru.ru_stime;        
  systim=timstr.tv_sec+(timstr.tv_usec/1000000.0);

  /* write final values and free memory */
  if (params.rank == 0) { // TODO: Use the final slice for extra operations, as it may have less work!
    printf("==done==\n");
    printf("Reynolds number:\t\t%.12E\n",(double)calc_reynolds(params, av_vels[params.maxIters-1]));
    printf("Elapsed time:\t\t\t%.6lf (s)\n", toc-tic);
    printf("Elapsed user CPU time:\t\t%.6lf (s)\n", usrtim);
    printf("Elapsed system CPU time:\t%.6lf (s)\n", systim);
  }

  write_values(params,cells,obstacles,av_vels);

  finalise(&params, &cells, &tmp_cells, &obstacles, &av_vels, &adjacency);

  // Free the send/recv buffers.
  free(sendbuf);
  free(recvbuf);

  // Shut down the MPI network.
  MPI_Finalize();

  return EXIT_SUCCESS;
}

#define PRINTRANK 1

int timestep(const t_param params, t_speed* cells, t_speed* tmp_cells, int* obstacles, t_adjacency* adjacency, my_float* sendbuf, my_float* recvbuf)
{
  const int tag = 0; // Can use to send extra data?
  MPI_Status status; // Struct for send/recv use.
  const int rnstart = params.slice_inner_end - params.slice_nx - 1; // Cell index we receive into from the north.
  const int snstart = params.slice_inner_end + 1; // Cell index we send from to the north.
  const int rsstart = params.slice_nx + 2; // Cell index we receive into from the south.
  const int ssstart = 0; // Cell index we send from to the south.
  const int restart = params.slice_nx; // Cell we recv into from the east
  const int swstart = 0;
  const int rwstart = 1;
  const int sestart = params.slice_nx + 1;
  const int xcount = params.slice_nx + 2; // The count of cells sent in each message.
  const int ycount = params.slice_ny + 2;
  const int send_len = (((params.slice_ny > params.slice_nx) ? params.slice_ny : params.slice_nx) + 2) * NSPEEDS; // The length of the buffer needed to send the cells.
  int interval; // The number of cells to skip between packing steps.

  accelerate_flow(params,cells,obstacles);
  propagate(params,cells,tmp_cells,adjacency);

  // Perform halo exchange. TODO: Handle other axis. TODO: We can get away with 2 less values if sgl x.
  if (!SINGLE_SLICE_Y) {
    interval = 1;
    // TODO: Better ways to do this?
    pack_row(sendbuf,snstart,interval,xcount,tmp_cells);
    // Send to the north, receive from the south.
    MPI_Sendrecv(sendbuf, send_len, MY_MPI_FLOAT, params.rank_north, tag,
		 recvbuf, send_len, MY_MPI_FLOAT, params.rank_south, tag,
		 MPI_COMM_WORLD, &status);
    unpack_row(recvbuf,rsstart,interval,xcount,tmp_cells,1);
    // Send to the south, receive from the north.
    pack_row(sendbuf,ssstart,interval,xcount,tmp_cells);
    MPI_Sendrecv(sendbuf, send_len, MY_MPI_FLOAT, params.rank_south, tag,
		 recvbuf, send_len, MY_MPI_FLOAT, params.rank_north, tag,
		 MPI_COMM_WORLD, &status);
    unpack_row(recvbuf,rnstart,interval,xcount,tmp_cells,0);
  }

  if (!SINGLE_SLICE_X) {
    interval = params.slice_nx + 2;
    pack_row(sendbuf,sestart,interval,ycount,tmp_cells);
    // Send to the east, receive from the west.
    MPI_Sendrecv(sendbuf, send_len, MY_MPI_FLOAT, params.rank_east, tag,
		 recvbuf, send_len, MY_MPI_FLOAT, params.rank_west, tag,
		 MPI_COMM_WORLD, &status);
    unpack_col(recvbuf,rwstart,interval,ycount,tmp_cells,1);
    // Send to the west, receive from the east.
    pack_row(sendbuf,swstart,interval,ycount,tmp_cells);
    MPI_Sendrecv(sendbuf, send_len, MY_MPI_FLOAT, params.rank_west, tag,
		 recvbuf, send_len, MY_MPI_FLOAT, params.rank_east, tag,
		 MPI_COMM_WORLD, &status);
    unpack_col(recvbuf,restart,interval,ycount,tmp_cells,0);
  }
  // Perform the diagonal exchanges in the 2D slicing case.
  if (0==1&&!SINGLE_SLICE_X && !SINGLE_SLICE_Y) {
    // Send NE, Recv SW. Need to use speed 5. Need to send NE buffer cell into SW inner
    MPI_Sendrecv(&(tmp_cells[params.slice_buff_len-1].speeds[5]), 1, MY_MPI_FLOAT, params.rank_ne, tag,
		 &(tmp_cells[params.slice_nx+3].speeds[5]), 1, MY_MPI_FLOAT, params.rank_sw, tag,
		 MPI_COMM_WORLD, &status);
    // Send SW, Recv NE. Use speed 7.
    MPI_Sendrecv(&(tmp_cells[0].speeds[7]), 1, MY_MPI_FLOAT, params.rank_sw, tag,
		 &(tmp_cells[params.slice_ny*(params.slice_nx+2)+params.slice_nx].speeds[5]), 1, MY_MPI_FLOAT, params.rank_ne, tag,
		 MPI_COMM_WORLD, &status);
    // Send NW, Recv SE. Use speed 6. Send NW buffer into SE inner.
    MPI_Sendrecv(&(tmp_cells[(params.slice_ny+1)*(params.slice_nx+2)].speeds[6]), 1, MY_MPI_FLOAT, params.rank_nw, tag,
		 &(tmp_cells[params.slice_nx+2+params.slice_nx].speeds[6]), 1, MY_MPI_FLOAT, params.rank_se, tag,
		 MPI_COMM_WORLD, &status);
    // Send SE, Recv NW. Use speed 8.
    MPI_Sendrecv(&(tmp_cells[params.slice_nx+1].speeds[8]), 1, MY_MPI_FLOAT, params.rank_se, tag,
		 &(tmp_cells[params.slice_ny*(params.slice_nx+2)+1].speeds[8]), 1, MY_MPI_FLOAT, params.rank_nw, tag,
		 MPI_COMM_WORLD, &status);
  }

  collision(params,cells,tmp_cells,obstacles);

  return EXIT_SUCCESS; 
}

int accelerate_flow(const t_param params, t_speed* cells, int* obstacles)
{
  const int ii = params.ny - 2;
  int jj, myii, myjj, my_cell;
  const my_float w1 = params.density * params.accel / 9.0; /* weighting factors */
  const my_float w2 = params.density * params.accel / 36.0;

  // THIS FUNCTION LOOPS OVER GLOBAL COORDINATES. REMEMBER TO TRANSLATE BEFORE ACCESS.
  for(jj=0;jj<params.nx;jj++) {
    if (within_slice_c(params, jj, ii)) {
      myii = ii - params.slice_global_ys + 1; // Get the local y coord.
      myjj = jj - params.slice_global_xs + 1; // Get the local x coord.
      // Offset curr_cell based upon the slice bounds.
      my_cell = myii * (params.slice_nx + 2) + myjj;
      
      /* if the cell is not occupied and
      ** we don't send a density negative */
      if( !obstacles[(myii - 1)*params.slice_nx+(myjj - 1)] && 
	  (cells[my_cell].speeds[3] - w1) > 0.0 &&
	  (cells[my_cell].speeds[6] - w2) > 0.0 &&
	  (cells[my_cell].speeds[7] - w2) > 0.0 ) {
	//printf("r%d wants to accel %d,%d in my grid %d,%d = %d\n", params.rank, jj, ii, myjj, myii, my_cell);
	/* increase 'east-side' densities */
	cells[my_cell].speeds[1] += w1;
	cells[my_cell].speeds[5] += w2;
	cells[my_cell].speeds[8] += w2;
	/* decrease 'west-side' densities */
	cells[my_cell].speeds[3] -= w1;
	cells[my_cell].speeds[6] -= w2;
	cells[my_cell].speeds[7] -= w2;
      }
    }
  }

  //printf("out of accel, %d\n", params.rank);
  return EXIT_SUCCESS;
}

int propagate_prep(const t_param params, t_adjacency* adjacency)
{
  int ii,jj;            /* generic counters */
  int x_e,x_w,y_n,y_s;  /* indices of neighbouring cells */

  // Need to prepare propagate in a slicewise manner. This makes things a bit harder.
  int curr_cell;

  /* loop over _all_ cells */
  for(ii=1;ii<params.slice_ny+1;ii++) {
    for(jj=1;jj<params.slice_nx+1;jj++) {
      curr_cell = ii*(params.slice_nx+2) + jj;
      /* determine indices of axis-direction neighbours
      ** respecting periodic boundary conditions (wrap around) */
      // Unless SINGLE_SLICE_X|Y is set, we do not need to worry about wrap around,
      // thanks to the presence of buffer space around us. If it is set, then we need to check
      // if we are on a boundary and borrow our own values from the opposite edge.
      x_e = (SINGLE_SLICE_X) ? (jj % params.slice_nx) + 1 : (jj + 1);
      x_w = (SINGLE_SLICE_X && jj == 1) ? params.slice_nx : (jj - 1);
      y_n = (SINGLE_SLICE_Y) ? (ii % params.slice_ny) + 1 : (ii + 1);
      y_s = (SINGLE_SLICE_Y && ii == 1) ? params.slice_ny : (ii - 1);
      //printf("prop of %d,%d: xe:%d xw:%d yn:%d ys:%d\n",jj,ii,x_e,x_w,y_n,y_s);

      //Pre-calculate the adjacent cells to propagate to.
      adjacency[curr_cell].index[1] = ii  * (params.slice_nx+2) + x_e; // E
      adjacency[curr_cell].index[2] = y_n * (params.slice_nx+2) + jj;  // N
      adjacency[curr_cell].index[3] = ii  * (params.slice_nx+2) + x_w; // W
      adjacency[curr_cell].index[4] = y_s * (params.slice_nx+2) + jj;  // S
      adjacency[curr_cell].index[5] = y_n * (params.slice_nx+2) + x_e; // NE
      adjacency[curr_cell].index[6] = y_n * (params.slice_nx+2) + x_w; // NW
      adjacency[curr_cell].index[7] = y_s * (params.slice_nx+2) + x_w; // SW
      adjacency[curr_cell].index[8] = y_s * (params.slice_nx+2) + x_e; // SE
    }
  }

  //printf("out of prop_prep, %d\n", params.rank);
  return EXIT_SUCCESS;
}

int propagate(const t_param params, t_speed* cells, t_speed* tmp_cells, t_adjacency* adjacency)
{
#if USE_PROPAGATE_CACHE
  int ii,jj,curr_cell; // Stop re-calculating the array index repeatedly.

  /* loop over _all_ cells */
  for(ii=1;ii<params.slice_ny+1;ii++) {
    for(jj=1;jj<params.slice_nx+1;jj++) {
      curr_cell = ii*(params.slice_nx+2) + jj;
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
    }
  }
#else // Non-cached propagate.
  int ii,jj,curr_cell; /* generic counters */
  int x_e,x_w,y_n,y_s; /* indices of neighbouring cells */

  /* loop over _all_ cells */
  for(ii=1;ii<params.slice_ny+1;ii++) {
    for(jj=1;jj<params.slice_nx+1;jj++) {
      curr_cell = ii*(params.slice_nx+2) + jj;
      /* determine indices of axis-direction neighbours
      ** respecting periodic boundary conditions (wrap around) */
      y_n = (SINGLE_SLICE_Y) ? (ii % params.slice_ny) + 1 : (ii + 1);
      x_e = (SINGLE_SLICE_X) ? (jj % params.slice_nx) + 1 : (jj + 1);
      y_s = (SINGLE_SLICE_Y && ii == 1) ? params.slice_ny : (ii - 1);
      x_w = (SINGLE_SLICE_X && jj == 1) ? params.slice_nx : (jj - 1);
      /* propagate densities to neighbouring cells, following
      ** appropriate directions of travel and writing into
      ** scratch space grid */
      tmp_cells[curr_cell].speeds[0] = cells[curr_cell].speeds[0];                     /* central cell, */
                                                                                       /* no movement   */
      tmp_cells[ii *(params.slice_nx+2) + x_e].speeds[1] = cells[curr_cell].speeds[1]; /* east */
      tmp_cells[y_n*(params.slice_nx+2) + jj].speeds[2]  = cells[curr_cell].speeds[2]; /* north */
      tmp_cells[ii *(params.slice_nx+2) + x_w].speeds[3] = cells[curr_cell].speeds[3]; /* west */
      tmp_cells[y_s*(params.slice_nx+2) + jj].speeds[4]  = cells[curr_cell].speeds[4]; /* south */
      tmp_cells[y_n*(params.slice_nx+2) + x_e].speeds[5] = cells[curr_cell].speeds[5]; /* north-east */
      tmp_cells[y_n*(params.slice_nx+2) + x_w].speeds[6] = cells[curr_cell].speeds[6]; /* north-west */
      tmp_cells[y_s*(params.slice_nx+2) + x_w].speeds[7] = cells[curr_cell].speeds[7]; /* south-west */
      tmp_cells[y_s*(params.slice_nx+2) + x_e].speeds[8] = cells[curr_cell].speeds[8]; /* south-east */
    }
  }
#endif

  //printf("out of prop, %d\n", params.rank);
  return EXIT_SUCCESS;
}

int collision(const t_param params, t_speed* cells, t_speed* tmp_cells, int* obstacles)
{
  int ii,jj,kk,obs_cell;           /* generic counters */
  const my_float c_sq = 1.0/3.0;  /* square of speed of sound */
  const my_float w0 = 4.0/9.0;    /* weighting factor */
  const my_float w1 = 1.0/9.0;    /* weighting factor */
  const my_float w2 = 1.0/36.0;   /* weighting factor */
  my_float u_x,u_y;               /* av. velocities in x and y directions */
  my_float u[NSPEEDS];            /* directional velocities */
  my_float d_equ[NSPEEDS];        /* equilibrium densities */
  my_float u_sq;                  /* squared velocity */
  my_float local_density;         /* sum of densities in a particular cell */
  int curr_cell; // Stop re-calculating the array index repeatedly.

  /* loop over the cells in the grid
  ** NB the collision step is called after
  ** the propagate step and so values of interest
  ** are in the scratch-space grid */
  for(ii=1;ii<params.slice_ny+1;ii++) {
    for(jj=1;jj<params.slice_nx+1;jj++) {
      curr_cell = ii*(params.slice_nx+2) + jj;
      obs_cell = (ii-1)*params.slice_nx + jj - 1;
      if(obstacles[obs_cell]) {
	/* called after propagate, so taking values from scratch space
	** mirroring, and writing into main grid */
	cells[curr_cell].speeds[1] = tmp_cells[curr_cell].speeds[3];
	cells[curr_cell].speeds[2] = tmp_cells[curr_cell].speeds[4];
	cells[curr_cell].speeds[3] = tmp_cells[curr_cell].speeds[1];
	cells[curr_cell].speeds[4] = tmp_cells[curr_cell].speeds[2];
	cells[curr_cell].speeds[5] = tmp_cells[curr_cell].speeds[7];
	cells[curr_cell].speeds[6] = tmp_cells[curr_cell].speeds[8];
	cells[curr_cell].speeds[7] = tmp_cells[curr_cell].speeds[5];
	cells[curr_cell].speeds[8] = tmp_cells[curr_cell].speeds[6];
      } else {
	/* don't consider occupied cells */
	/* compute local density total */
	local_density = 0.0;
	for(kk=0;kk<NSPEEDS;kk++) {
	  local_density += tmp_cells[curr_cell].speeds[kk];
	}
	//printf("%d,%d r%d thinks has LoD: %f\n",jj+params.slice_global_xs-1,ii+params.slice_global_ys-1,params.rank,local_density);

	/* compute x velocity component */
	u_x = (tmp_cells[curr_cell].speeds[1] + 
	       tmp_cells[curr_cell].speeds[5] + 
	       tmp_cells[curr_cell].speeds[8]
	       - (tmp_cells[curr_cell].speeds[3] + 
		  tmp_cells[curr_cell].speeds[6] + 
		  tmp_cells[curr_cell].speeds[7]))
	  / local_density;

	/* compute y velocity component */
	u_y = (tmp_cells[curr_cell].speeds[2] + 
	       tmp_cells[curr_cell].speeds[5] + 
	       tmp_cells[curr_cell].speeds[6]
	       - (tmp_cells[curr_cell].speeds[4] + 
		  tmp_cells[curr_cell].speeds[7] + 
		  tmp_cells[curr_cell].speeds[8]))
	  / local_density;

	/* velocity squared */ 
	u_sq = u_x * u_x + u_y * u_y;
	/* directional velocity components */
	u[1] =   u_x;        /* east */
	u[2] =         u_y;  /* north */
	u[3] = - u_x;        /* west */
	u[4] =       - u_y;  /* south */
	u[5] =   u_x + u_y;  /* north-east */
	u[6] = - u_x + u_y;  /* north-west */
	u[7] = - u_x - u_y;  /* south-west */
	u[8] =   u_x - u_y;  /* south-east */
	/* equilibrium densities */
	/* zero velocity density: weight w0 */
	d_equ[0] = w0 * local_density * (1.0 - u_sq / (2.0 * c_sq));
	/* axis speeds: weight w1 */
	d_equ[1] = w1 * local_density * (1.0 + u[1] / c_sq
					 + (u[1] * u[1]) / (2.0 * c_sq * c_sq)
					 - u_sq / (2.0 * c_sq));
	d_equ[2] = w1 * local_density * (1.0 + u[2] / c_sq
					 + (u[2] * u[2]) / (2.0 * c_sq * c_sq)
					 - u_sq / (2.0 * c_sq));
	d_equ[3] = w1 * local_density * (1.0 + u[3] / c_sq
					 + (u[3] * u[3]) / (2.0 * c_sq * c_sq)
					 - u_sq / (2.0 * c_sq));
	d_equ[4] = w1 * local_density * (1.0 + u[4] / c_sq
					 + (u[4] * u[4]) / (2.0 * c_sq * c_sq)
					 - u_sq / (2.0 * c_sq));
	/* diagonal speeds: weight w2 */
	d_equ[5] = w2 * local_density * (1.0 + u[5] / c_sq
					 + (u[5] * u[5]) / (2.0 * c_sq * c_sq)
					 - u_sq / (2.0 * c_sq));
	d_equ[6] = w2 * local_density * (1.0 + u[6] / c_sq
					 + (u[6] * u[6]) / (2.0 * c_sq * c_sq)
					 - u_sq / (2.0 * c_sq));
	d_equ[7] = w2 * local_density * (1.0 + u[7] / c_sq
					 + (u[7] * u[7]) / (2.0 * c_sq * c_sq)
					 - u_sq / (2.0 * c_sq));
	d_equ[8] = w2 * local_density * (1.0 + u[8] / c_sq
					 + (u[8] * u[8]) / (2.0 * c_sq * c_sq)
					 - u_sq / (2.0 * c_sq));
	/* relaxation step */
	for(kk=0;kk<NSPEEDS;kk++) {
	  cells[curr_cell].speeds[kk] = (tmp_cells[curr_cell].speeds[kk]
						 + params.omega * 
						 (d_equ[kk] - tmp_cells[curr_cell].speeds[kk]));
	}
      }
    }
  }

  //printf("out of coll, %d\n", params.rank);
  return EXIT_SUCCESS; 
}

int initialise(const char* paramfile, const char* obstaclefile,
	       t_param* params, t_speed** cells_ptr, t_speed** tmp_cells_ptr, 
	       int** obstacles_ptr, my_float** av_vels_ptr, t_adjacency** adjacency)
{
  char   message[1024];  /* message buffer */
  FILE   *fp;            /* file pointer */
  int    ii;             /* generic counters */
  int    xt,yt,xx,yy;          /* generic array indices */
  int    blocked;        /* indicates whether a cell is blocked by an obstacle */ 
  int    retval;         /* to hold return value for checking */
  double w0,w1,w2;       /* weighting factors */
  int extra_rows = 0; // The number of rows extra on the final slice.

  /* open the parameter file */
  fp = fopen(paramfile,"r");
  if (fp == NULL) {
    sprintf(message,"could not open input parameter file: %s", paramfile);
    die(message,__LINE__,__FILE__);
  }

  /* read in the parameter values */
  retval = fscanf(fp,"%d\n",&(params->nx));
  if(retval != 1) die ("could not read param file: nx",__LINE__,__FILE__);
  retval = fscanf(fp,"%d\n",&(params->ny));
  if(retval != 1) die ("could not read param file: ny",__LINE__,__FILE__);
  retval = fscanf(fp,"%d\n",&(params->maxIters));
  if(retval != 1) die ("could not read param file: maxIters",__LINE__,__FILE__);
  retval = fscanf(fp,"%d\n",&(params->reynolds_dim));
  if(retval != 1) die ("could not read param file: reynolds_dim",__LINE__,__FILE__);
  retval = fscanf(fp,MY_FLOAT_PATTERN,&(params->density));
  if(retval != 1) die ("could not read param file: density",__LINE__,__FILE__);
  retval = fscanf(fp,MY_FLOAT_PATTERN,&(params->accel));
  if(retval != 1) die ("could not read param file: accel",__LINE__,__FILE__);
  retval = fscanf(fp,MY_FLOAT_PATTERN,&(params->omega));
  if(retval != 1) die ("could not read param file: omega",__LINE__,__FILE__);

  /* and close up the file */
  fclose(fp);

  /* 
  ** Allocate memory.
  **
  ** Remember C is pass-by-value, so we need to
  ** pass pointers into the initialise function.
  **
  ** NB we are allocating a 1D array, so that the
  ** memory will be contiguous.  We still want to
  ** index this memory as if it were a (row major
  ** ordered) 2D array, however.  We will perform
  ** some arithmetic using the row and column
  ** coordinates, inside the square brackets, when
  ** we want to access elements of this array.
  **
  ** Note also that we are using a structure to
  ** hold an array of 'speeds'.  We will allocate
  ** a 1D array of these structs.
  */

  // Each grid will now be split into smaller subsections.

  if (SINGLE_SLICE_Y && SINGLE_SLICE_X) {
    // Single sliced in both directions, must be only one process!
    if (params->size == 1) {
      params->rank_north = params->rank_south = params->rank_east = params->rank_west = params->rank;
    } else {
      die("executable is set to single slice mode, cannot run multiple processes",__LINE__,__FILE__);
    }
  } else if (SINGLE_SLICE_X) {
    // Divide the problem space into slices row wise.
  
    // We need to assert that the number of rows we are working on is >= the number of processes.
    if (params->size > params->ny) {
      die("problem space is too small for the current processor count",__LINE__,__FILE__);
    }

    // Set the slice dimensions.
    params->slice_nx = params->nx;
    params->slice_ny = (int)(params->ny / params->size);

    // Set the global offset for this slice
    params->slice_global_xs = 0;
    params->slice_global_ys = params->slice_ny * params->rank;

    // Set our neighbouring slice indices.
    params->rank_east = params->rank_west = params->rank_nw = params->rank_sw = params->rank_ne = params->rank_se = params->rank;
    params->rank_north = (params->rank + 1) % params->size;
    params->rank_south = (params->rank == 0) ? params->size - 1 : params->rank - 1;

    // Add any remaining rows to the final slice.
    if (params->rank == params->size - 1) {
      extra_rows = params->ny - (params->slice_ny * params->size);
      params->slice_ny += extra_rows;
    }
  } else if (SINGLE_SLICE_Y) {
    // TODO: Implement me. Divide the problem space into slices column wise.
    die("unimplemented",__LINE__,__FILE__);
  } else {
    // Split the cells down the middle, to make two columns of ranks.
    params->slice_nx = (int)(params->nx / 2);
    params->slice_ny = (int)(2 * params->ny / params->size);

    if ((params->nx & 1) == 1) {
      // Odd number of columns, add extra to the rightmost slices.
      if ((params->rank & 1) == 1) {
	params->slice_nx++;
      }
    }

    params->slice_global_ys = (int)(params->rank / 2) * params->slice_ny;

    // The final row of slices need to accomodate any remaining rows in the global grid.
    if (params->rank >= params->size - 2) {
      //extra_rows = params->ny - (params->slice_ny * params->size);
      extra_rows = (int)((params->ny * 2) % params->size) / 2;
      params->slice_ny += extra_rows;
    }

    // Set the global offset for this slice
    params->slice_global_xs = ((params->rank & 1) == 0) ? 0 : (int)(params->nx / 2);

    // Set our neighbouring slice indices.
    int ssx = 2; // The number of columns of slices.
    int ssy = params->size / ssx; // The number of rows of slices.
    int sjj = params->rank & 1; // The x co-ord of this slice in slice grid.
    int sii = params->rank / ssx;
    int x_e = (sjj + 1) % ssx;
    int x_w = (sjj == 0) ? ssx - 1 : sjj - 1;
    int y_n = (sii + 1) % ssy;
    int y_s = (sii == 0) ? ssy - 1 : sii - 1;
    if (params->rank != sii * ssx + sjj) {
      die("We've forgotten who we are!",__LINE__,__FILE__);
    }
    params->rank_east  = sii * ssx + x_e;
    params->rank_north = y_n * ssx + sjj;
    params->rank_west  = sii * ssx + x_w;
    params->rank_south = y_s * ssx + sjj;
    params->rank_ne    = y_n * ssx + x_e;
    params->rank_nw    = y_n * ssx + x_w;
    params->rank_sw    = y_s * ssx + x_w;
    params->rank_se    = y_s * ssx + x_e;
  }

  // Calculate the slice len. Strategy generic
  params->slice_len = params->slice_ny * params->slice_nx;

  // Total size of the buffer including exchange space. Strategy generic.
  params->slice_buff_len = (params->slice_nx + 2) * (params->slice_ny + 2);

  // Want to know the index in a local sense for loops. Strategy generic.
  // snx for the adjacent row, 2 for the corners, 1 for the west edge.
  params->slice_inner_start = params->slice_nx + 2 + 1;
  // The slice end is nx * ny away. Need to account for buffer space +2(ny - 1)
  params->slice_inner_end = params->slice_inner_start +
    (params->slice_nx * params->slice_ny) + (2 * params->slice_ny) - 2;

  // Global index of the slice ending. Should be strategy generic.
  params->slice_global_xe = params->slice_global_xs + params->slice_nx;
  params->slice_global_ye = params->slice_global_ys + params->slice_ny;

  /* main grid */
  *cells_ptr = (t_speed*)malloc(sizeof(t_speed)*params->slice_buff_len);
  if (*cells_ptr == NULL) 
    die("cannot allocate memory for cells",__LINE__,__FILE__);

  /* 'helper' grid, used as scratch space */
  *tmp_cells_ptr = (t_speed*)malloc(sizeof(t_speed)*params->slice_buff_len);
  if (*tmp_cells_ptr == NULL) 
    die("cannot allocate memory for tmp_cells",__LINE__,__FILE__);

  /* the map of obstacles */
  *obstacles_ptr = malloc(sizeof(int)*params->slice_len);
  if (*obstacles_ptr == NULL) 
    die("cannot allocate memory for obstacles",__LINE__,__FILE__);

#if USE_PROPAGATION_CACHE
  /* adjacency for propagate */
  *adjacency = calloc(params->slice_buff_len, sizeof(t_adjacency));
  if (*adjacency == NULL)
    die("cannot allocate adjacency memory",__LINE__,__FILE__);
#endif

  /* initialise densities */
  w0 = params->density * 4.0/9.0;
  w1 = params->density      /9.0;
  w2 = params->density      /36.0;

  // Only do the current slice!
  for(ii=0;ii<params->slice_buff_len;ii++) {
    /* centre */
    (*cells_ptr)[ii].speeds[0] = w0;
    /* axis directions */
    (*cells_ptr)[ii].speeds[1] = w1;
    (*cells_ptr)[ii].speeds[2] = w1;
    (*cells_ptr)[ii].speeds[3] = w1;
    (*cells_ptr)[ii].speeds[4] = w1;
    /* diagonals */
    (*cells_ptr)[ii].speeds[5] = w2;
    (*cells_ptr)[ii].speeds[6] = w2;
    (*cells_ptr)[ii].speeds[7] = w2;
    (*cells_ptr)[ii].speeds[8] = w2;
  }

  /* first set all cells in obstacle array to zero */ 
  for(ii=0;ii<params->slice_len;ii++) {
    (*obstacles_ptr)[ii] = 0;
  }

  /* open the obstacle data file */
  fp = fopen(obstaclefile,"r");
  if (fp == NULL) {
    sprintf(message,"could not open input obstacles file: %s", obstaclefile);
    die(message,__LINE__,__FILE__);
  }

  /* read-in the blocked cells list */
  while( (retval = fscanf(fp,"%d %d %d\n", &xx, &yy, &blocked)) != EOF) {
    /* some checks */
    if ( retval != 3)
      die("expected 3 values per line in obstacle file",__LINE__,__FILE__);
    if ( xx<0 || xx>params->nx-1 )
      die("obstacle x-coord out of range",__LINE__,__FILE__);
    if ( yy<0 || yy>params->ny-1 )
      die("obstacle y-coord out of range",__LINE__,__FILE__);
    if ( blocked != 1 ) 
      die("obstacle blocked value should be 1",__LINE__,__FILE__);
    // check that the blockage actually is within our bounds.
    if (within_slice_c(*params, xx, yy)) {
      // Calculate the obstacle index in our grid.
      xt=xx;yt=yy;
      xx = xx - params->slice_global_xs;
      yy = yy - params->slice_global_ys;
      ii = (yy * params->slice_nx) + xx;

      //printf("Block r%d: (%d,%d) %d,%d @ %d\n",params->rank,xt,yt,xx,yy,ii);

      // Sanity check.
      if (ii < 0 || ii >= params->slice_len) {
	printf("Rank: %d\txx: %d\tyy: %d\tii: %d\txt: %d\tyt: %d\n",params->rank,xx,yy,ii,xt,yt);
	die("obstacle out of bounds in slice",__LINE__,__FILE__);
      }

      /* assign to array */
      (*obstacles_ptr)[ii] = blocked;
    }
  }

  /* and close the file */
  fclose(fp);

  /* 
  ** allocate space to hold a record of the avarage velocities computed 
  ** at each timestep
  */
  // We can combine means (m0 * n0 + m1 * n1 ... / n) from all the processes later.
  *av_vels_ptr = (my_float*)malloc(sizeof(my_float)*params->maxIters);

  return EXIT_SUCCESS;
}

int finalise(const t_param* params, t_speed** cells_ptr, t_speed** tmp_cells_ptr,
	     int** obstacles_ptr, my_float** av_vels_ptr, t_adjacency** adjacency)
{
  /* 
  ** free up allocated memory
  */
  free(*cells_ptr);
  *cells_ptr = NULL;

  free(*tmp_cells_ptr);
  *tmp_cells_ptr = NULL;

  free(*obstacles_ptr);
  *obstacles_ptr = NULL;

  free(*av_vels_ptr);
  *av_vels_ptr = NULL;

#if USE_PROPAGATION_CACHE
  free(*adjacency);
  *adjacency = NULL;
#endif

  return EXIT_SUCCESS;
}

my_float av_velocity(const t_param params, t_speed* cells, int* obstacles)
{
  int    ii,jj,kk,curr_cell;       /* generic counters */
  int    tot_cells = 0;  /* no. of cells used in calculation */
  my_float local_density;  /* total density in cell */
  my_float u_x;            /* x-component of velocity for current cell */
  my_float u_y;            /* y-component of velocity for current cell */
  my_float tot_u;          /* accumulated magnitudes of velocity for each cell */
  my_float global_tot_u = 0.0;
  int global_tot_cells = 0;

  /* initialise */
  tot_u = 0.0;

  /* loop over all non-blocked cells */
  for(ii=1;ii<params.slice_ny+1;ii++) {
    for(jj=1;jj<params.slice_nx+1;jj++) {
      curr_cell = ii*(params.slice_nx+2) + jj;
      /* ignore occupied cells */
      if(!obstacles[(ii-1)*params.slice_nx + (jj-1)]) {
	//printf("Looking at: %d (%d,%d)\n", curr_cell, jj,ii);
	/* local density total */
	local_density = 0.0;
	for(kk=0;kk<NSPEEDS;kk++) {
	  local_density += cells[curr_cell].speeds[kk];
	}
	//printf("(%d,%d) has LD %f\n",params.slice_global_xs+jj-1,params.slice_global_ys+ii-1,local_density);
	/* x-component of velocity */
	u_x = (cells[curr_cell].speeds[1] + 
	       cells[curr_cell].speeds[5] + 
	       cells[curr_cell].speeds[8]
	       - (cells[curr_cell].speeds[3] + 
		  cells[curr_cell].speeds[6] + 
		  cells[curr_cell].speeds[7])) / 
	  local_density;
	/* compute y velocity component */
	u_y = (cells[curr_cell].speeds[2] + 
	       cells[curr_cell].speeds[5] + 
	       cells[curr_cell].speeds[6]
	       - (cells[curr_cell].speeds[4] + 
		  cells[curr_cell].speeds[7] + 
		  cells[curr_cell].speeds[8])) /
	  local_density;
	/* accumulate the norm of x- and y- velocity components */
	tot_u += my_sqrt((u_x * u_x) + (u_y * u_y));
	/* increase counter of inspected cells */
	++tot_cells;
      }
    }
  }

  //printf("av_vel r%d %lf\n", params.rank, tot_u / (my_float)tot_cells);

  // Use a reduction to sum the totals across processes. TODO: Can we do this in one reduce call?
  MPI_Reduce(&tot_cells, &global_tot_cells, 1, MPI_INT, MPI_SUM, 0, MPI_COMM_WORLD);
  MPI_Reduce(&tot_u, &global_tot_u, 1, MY_MPI_FLOAT, MPI_SUM, 0, MPI_COMM_WORLD);

  if (params.rank == 0) {
    // We should have the reduced value.
    //printf("out of av_vel, %1.9lf\n", global_tot_u / (my_float)global_tot_cells);
    return global_tot_u / (my_float)global_tot_cells;
  } else {
    return NAN;
  }
}

my_float calc_reynolds(const t_param params, const my_float av_vel)
{
  const my_float viscosity = 1.0 / 6.0 * (2.0 / params.omega - 1.0);
  return av_vel * params.reynolds_dim / viscosity;
}

my_float total_density(const t_param params, t_speed* cells)
{
  int ii,jj,kk;        /* generic counters */
  my_float total = 0.0;  /* accumulator */

  for(ii=0;ii<params.ny;ii++) {
    for(jj=0;jj<params.nx;jj++) {
      for(kk=0;kk<NSPEEDS;kk++) {
	total += cells[ii*params.nx + jj].speeds[kk];
      }
    }
  }

  return total;
}

int write_values(const t_param params, t_speed* cells, int* obstacles, my_float* av_vels)
{
  FILE* fp;                                /* file pointer */
  int ii,jj,kk,my_cell,myii,myjj,obs_cell; /* generic counters */
  const double c_sq = 1.0/3.0;             /* sq. of speed of sound */
  double local_density;                    /* per grid cell sum of densities */
  double pressure;                         /* fluid pressure in grid cell */
  double u_x;                              /* x-component of velocity in grid cell */
  double u_y;                              /* y-component of velocity in grid cell */
  double u;                                /* norm--root of summed squares--of u_x and u_y */
  int have_fp = 0;

  // This function uses hackery beyond your wildest imagination. Don't read on.
  // I cannot warn you enough. Efficiency does not exist here. If it ain't broke,
  // don't fix it. Murphy's Law doesn't mean that something bad will happen. It means that
  // whatever can happen, will happen. I apologise to everyone who has ever trusted me.
  // Forgive me.

  // THIS FUNCTION LOOPS OVER GLOBAL COORDINATES. REMEMBER TO TRANSLATE BEFORE ACCESS.
  for(ii=0;ii<params.ny;ii++) {
    for(jj=0;jj<params.nx;jj++) {
      // Check if the current slice should be handling this cell.
      if (!within_slice_c(params, jj, ii)) {
	// Close the fp if we have it and we don't need it this iter.
	if (have_fp) {
	  fclose(fp);
	  have_fp = 0;
	}
      }

      // Need to sync here, so that all ranks that are not writing this turn do not
      // have the file opened. The rank that needs the file may or may not already have
      // the file opened for writing.
      MPI_Barrier(MPI_COMM_WORLD);

      if (within_slice_c(params, jj, ii)) {
	// If we don't already have the fp, then open.
	if (!have_fp) {
	  fp = fopen(FINALSTATEFILE,(ii == 0 && jj == 0) ? "w" : "a");
	  if (fp == NULL) {
	    die("could not open file output file",__LINE__,__FILE__);
	  }
	  have_fp = 1;
	}
	myii = ii - params.slice_global_ys + 1; // Get the local y coord.
	myjj = jj - params.slice_global_xs + 1; // Get the local x coord.
	// Offset curr_cell based upon the slice bounds.
	my_cell = myii * (params.slice_nx + 2) + myjj;
	// The obstacle cell is not indexed the same.
	obs_cell = (myii-1)*params.slice_nx+(myjj-1);
      
	/* an occupied cell */
	if(obstacles[obs_cell]) {
	  u_x = u_y = u = 0.0;
	  pressure = params.density * c_sq;
	}
	/* no obstacle */
	else {
	  local_density = 0.0;
	  for(kk=0;kk<NSPEEDS;kk++) {
	    local_density += cells[my_cell].speeds[kk];
	  }
	  /* compute x velocity component */
	  u_x = (cells[my_cell].speeds[1] + 
		 cells[my_cell].speeds[5] +
		 cells[my_cell].speeds[8]
		 - (cells[my_cell].speeds[3] + 
		    cells[my_cell].speeds[6] + 
		    cells[my_cell].speeds[7]))
	    / local_density;
	  /* compute y velocity component */
	  u_y = (cells[my_cell].speeds[2] + 
		 cells[my_cell].speeds[5] + 
		 cells[my_cell].speeds[6]
		 - (cells[my_cell].speeds[4] + 
		    cells[my_cell].speeds[7] + 
		    cells[my_cell].speeds[8]))
	    / local_density;
	  /* compute norm of velocity */
	  u = my_sqrt((u_x * u_x) + (u_y * u_y));
	  /* compute pressure */
	  pressure = local_density * c_sq;
	}
	/* write to file */
	// THIS IS INSANELY INEFFICIENT, FIX ME
	//fp = fopen(FINALSTATEFILE,(ii == 0 && jj == 0) ? "w" : "a");
	//if (fp == NULL) {
	  //die("could not open file output file",__LINE__,__FILE__);
	//}
	fprintf(fp,"%d %d %.12E %.12E %.12E %.12E %d\n",jj,ii,u_x,u_y,u,pressure,obstacles[obs_cell]);
	//fclose(fp);
      } // if within slice

      // Need to synchronise each process so they don't attempt to write simultaneously.
      MPI_Barrier(MPI_COMM_WORLD);
    } // jj for
  } // ii for

  // The last iter will leave the file opened.
  if (have_fp) {
    fclose(fp);
    have_fp = 0;
  }

  // Only rank 0 knows the average velocities.
  if (params.rank == 0) {
    fp = fopen(AVVELSFILE,"w");
    if (fp == NULL) {
      die("could not open file output file",__LINE__,__FILE__);
    }
    for (ii=0;ii<params.maxIters;ii++) {
      fprintf(fp,"%d:\t%.12E\n", ii, (double)av_vels[ii]);
    }

    fclose(fp);
  }

  return EXIT_SUCCESS;
}

void die(const char* message, const int line, const char *file)
{
  fprintf(stderr, "Error at line %d of file %s:\n", line, file);
  fprintf(stderr, "%s\n",message);
  fflush(stderr);
  MPI_Abort(MPI_COMM_WORLD,EXIT_FAILURE);
}

void usage(const char* exe)
{
  fprintf(stderr, "Usage: %s <paramfile> <obstaclefile>\n", exe);
  exit(EXIT_FAILURE);
}

inline int within_slice_c(const t_param params, const int jj, const int ii)
{
  // jj == x, ii == y
  return
    (jj >= params.slice_global_xs) &&
    (jj <  params.slice_global_xe) &&
    (ii >= params.slice_global_ys) &&
    (ii <  params.slice_global_ye);
}

inline int within_slice(const t_param params, const int index)
{
  const int jj = index % params.nx;
  const int ii = index / params.nx;
  return within_slice_c(params, jj, ii);
}

inline void pack_row(my_float* packed, const int start, const int interval, const int count, t_speed* cells) {
  //printf("Sending from %d + %d\n",start,count);
  for (int ii = 0;ii<count;ii++) {
    for (int kk = 0;kk<NSPEEDS;kk++) {
      packed[ii*NSPEEDS+kk] = cells[ii*interval+start].speeds[kk];
    }
  }
}

inline void unpack_row(my_float* packed, const int start, const int interval, const int count, t_speed* cells, int sixtwofive) {
  //TODO: Remove interval param
  //printf("Recving into %d + %d\n",start,count);
  for (int ii = 0;ii<count;ii++) {
    if (sixtwofive) {
      cells[ii+start].speeds[6] = packed[ii*NSPEEDS+6];
      cells[ii+start].speeds[2] = packed[ii*NSPEEDS+2];
      cells[ii+start].speeds[5] = packed[ii*NSPEEDS+5];
    } else {
      cells[ii+start].speeds[7] = packed[ii*NSPEEDS+7];
      cells[ii+start].speeds[4] = packed[ii*NSPEEDS+4];
      cells[ii+start].speeds[8] = packed[ii*NSPEEDS+8];
    }
  }
}

// TODO: Combine with unpack row.
inline void unpack_col(my_float* packed, const int start, const int interval, const int count, t_speed* cells, int fiveoneeight) {
  //printf("Recving into %d + %d\n",start,count);
  for (int ii = 0;ii<count;ii++) {
    // When at the edge of the slice, we have a cell where only the outward diagonal
    // has been set by propagate. Thus, copying the entire outward edge of the cell is writing
    // bad values to actual cells. This bug is masked in the one way slicing case!
    if (fiveoneeight) {
      cells[ii*interval+start].speeds[5] = packed[ii*NSPEEDS+5];
      cells[ii*interval+start].speeds[1] = packed[ii*NSPEEDS+1];
      cells[ii*interval+start].speeds[8] = packed[ii*NSPEEDS+8];
    } else {
      cells[ii*interval+start].speeds[6] = packed[ii*NSPEEDS+6];
      cells[ii*interval+start].speeds[3] = packed[ii*NSPEEDS+3];
      cells[ii*interval+start].speeds[7] = packed[ii*NSPEEDS+7];
    }
  }
}

void pobs(const t_param params, int* obstacles) {
  int ii,jj,curr_cell;
  for(ii=0;ii<params.slice_ny;ii++) {
    for(jj=0;jj<params.slice_nx;jj++) {
      curr_cell = ii*params.slice_nx + jj;
      printf(obstacles[curr_cell] ? "#" : "_");
    }
    printf("\n");
  }
}

void print_row(const int rank, const int start, const int count, t_speed* cells) {
  for (int ii = start;ii<start+count;ii++) {
    for (int kk = 0;kk<NSPEEDS;kk++) {
      printf("r%d %d.%d: %f\n", rank, ii, kk, cells[ii].speeds[kk]);
    }
  }
}

void print_grid(const t_param params, t_speed* cells) {
  for (int ii = 0;ii<params.slice_ny+2;ii++) {
    for (int jj = 0;jj<params.slice_nx+2;jj++) {
      printf("%f,%f,%f\n", cells[ii*(params.slice_nx+2)+jj].speeds[6], cells[ii*(params.slice_nx+2)+jj].speeds[2], cells[ii*(params.slice_nx+2)+jj].speeds[5]);
      printf("%f,%f,%f\n", cells[ii*(params.slice_nx+2)+jj].speeds[3], cells[ii*(params.slice_nx+2)+jj].speeds[0], cells[ii*(params.slice_nx+2)+jj].speeds[1]);
      printf("%f,%f,%f\n", cells[ii*(params.slice_nx+2)+jj].speeds[7], cells[ii*(params.slice_nx+2)+jj].speeds[4], cells[ii*(params.slice_nx+2)+jj].speeds[8]);
      printf("\n\n");
    }
    printf("---------\n");
  }
}

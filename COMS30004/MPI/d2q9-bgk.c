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
#else
typedef double my_float;
#define my_sqrt sqrt
#define MY_FLOAT_PATTERN "%lf\n"
#endif

// If true, slices should not communicate in this direction, as they are alone in this axis.
#define SINGLE_SLICE_Y 0
#define SINGLE_SLICE_X 1

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
int timestep(const t_param params, t_speed* cells, t_speed* tmp_cells, int* obstacles, t_adjacency* adjacency);
int accelerate_flow(const t_param params, t_speed* cells, int* obstacles);
int propagate_prep(const t_param params, t_adjacency* adjacency);
int propagate(const t_param params, t_speed* cells, t_speed* tmp_cells, t_adjacency* adjacency);
int collision(const t_param params, t_speed* cells, t_speed* tmp_cells, int* obstacles);
int write_values(const t_param params, t_speed* cells, int* obstacles, my_float* av_vels);

/* finalise, including freeing up allocated memory */
int finalise(const t_param* params, t_speed** cells_ptr, t_speed** tmp_cells_ptr,
	     int** obstacles_ptr, my_float** av_vels_ptr);

/* Sum all the densities in the grid.
** The total should remain constant from one timestep to the next. */
my_float total_density(const t_param params, t_speed* cells);

/* compute average velocity */
my_float av_velocity(const t_param params, t_speed* cells, int* obstacles);

/* calculate Reynolds number */
my_float calc_reynolds(const t_param params, t_speed* cells, int* obstacles);

/* utility functions */
void die(const char* message, const int line, const char *file);
void usage(const char* exe);
int within_slice_c(const t_param params, const int jj, const int ii);
int within_slice(const t_param params, const int index);
//int slice_index(const t_param params, const int index);

/*
** main program:
** initialise, timestep loop, finalise
*/
int main(int argc, char* argv[])
{
  char*    paramfile = NULL;    /* name of the input parameter file */
  char*    obstaclefile = NULL; /* name of a the input obstacle file */
  t_param  params;              /* struct to hold parameter values */
  t_speed* cells     = NULL;    /* grid containing fluid densities */
  t_speed* tmp_cells = NULL;    /* scratch space */
  int*     obstacles = NULL;    /* grid indicating which cells are blocked */
  my_float*  av_vels   = NULL;    /* a record of the av. velocity computed for each timestep */
  int      ii;                  /* generic counter */
  struct timeval timstr;        /* structure to hold elapsed time */
  struct rusage ru;             /* structure to hold CPU time--system and user */
  double tic,toc;               /* floating point numbers to calculate elapsed wallclock time */
  double usrtim;                /* floating point number to record elapsed user CPU time */
  double systim;                /* floating point number to record elapsed system CPU time */
  t_adjacency* adjacency = NULL; /* store adjacency for each cell in each direction for propagate. */

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

  // TODO: NOPE
  if (params.size != 2)
      die("bad problem size",__LINE__,__FILE__);

  printf("I'm rank %d of %d", params.rank, params.size);
  MPI_Barrier(MPI_COMM_WORLD);

  /* initialise our data structures and load values from file */
  initialise(paramfile, obstaclefile, &params, &cells, &tmp_cells, &obstacles, &av_vels, &adjacency);

  // Synchronise all processes before we enter the simulation loop.
  MPI_Barrier(MPI_COMM_WORLD);

  /* iterate for maxIters timesteps */
  gettimeofday(&timstr,NULL);
  tic=timstr.tv_sec+(timstr.tv_usec/1000000.0);

  // Can we do this outside the timing? Probably not!
  propagate_prep(params, adjacency);
  MPI_Barrier(MPI_COMM_WORLD); // TODO: NOPE

  //  for (ii=0;ii<params.maxIters;ii++) {
  ii=0;
    timestep(params,cells,tmp_cells,obstacles,adjacency);
    av_vels[ii] = av_velocity(params,cells,obstacles);
#ifdef DEBUG
    printf("==timestep: %d==\n",ii);
    printf("av velocity: %.12E\n", av_vels[ii]);
    printf("tot density: %.12E\n",total_density(params,cells));
#endif
    //}
  gettimeofday(&timstr,NULL);
  toc=timstr.tv_sec+(timstr.tv_usec/1000000.0);
  getrusage(RUSAGE_SELF, &ru);
  timstr=ru.ru_utime;        
  usrtim=timstr.tv_sec+(timstr.tv_usec/1000000.0);
  timstr=ru.ru_stime;        
  systim=timstr.tv_sec+(timstr.tv_usec/1000000.0);

  /* write final values and free memory */
  printf("==done==\n");
  printf("Reynolds number:\t\t%.12E\n",(double)calc_reynolds(params,cells,obstacles));
  printf("Elapsed time:\t\t\t%.6lf (s)\n", toc-tic);
  printf("Elapsed user CPU time:\t\t%.6lf (s)\n", usrtim);
  printf("Elapsed system CPU time:\t%.6lf (s)\n", systim);
  write_values(params,cells,obstacles,av_vels);
  finalise(&params, &cells, &tmp_cells, &obstacles, &av_vels);

  MPI_Finalize();
  
  return EXIT_SUCCESS;
}

int timestep(const t_param params, t_speed* cells, t_speed* tmp_cells, int* obstacles, t_adjacency* adjacency)
{
  accelerate_flow(params,cells,obstacles);
  propagate(params,cells,tmp_cells,adjacency);
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
      myii = ii - params.slice_global_ys; // Get the local y coord.
      myjj = jj - params.slice_global_xs; // Get the local x coord.
      // Offset curr_cell based upon the slice bounds.
      my_cell = myii * params.slice_nx + myjj;
      /* if the cell is not occupied and
      ** we don't send a density negative */
      if( !obstacles[my_cell] && 
	  (cells[my_cell].speeds[3] - w1) > 0.0 &&
	  (cells[my_cell].speeds[6] - w2) > 0.0 &&
	  (cells[my_cell].speeds[7] - w2) > 0.0 ) {
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


  printf("out of accel, %d\n", params.rank);
  return EXIT_SUCCESS;
}

int propagate_prep(const t_param params, t_adjacency* adjacency)
{
  int ii,jj;            /* generic counters */
  int x_e,x_w,y_n,y_s;  /* indices of neighbouring cells */

  // Need to prepare propagate in a slicewise manner. This makes things a bit harder.
  int curr_cell;

  // PROTIP: ii is y, jj is x

  /* loop over _all_ cells */
  for(ii=1;ii<params.slice_ny+1;ii++) {
    for(jj=1;jj<params.slice_nx+1;jj++) {
      curr_cell = ii*params.nx + jj;
      /* determine indices of axis-direction neighbours
      ** respecting periodic boundary conditions (wrap around) */
      // Unless SINGLE_SLICE_X|Y is set, we do not need to worry about wrap around,
      // thanks to the presence of buffer space around us. If it is set, then we need to check
      // if we are on a boundary and borrow our own values from the opposite edge.
      x_e = (SINGLE_SLICE_X) ? (jj % params.slice_nx) + 1 : (jj + 1);
      x_w = (SINGLE_SLICE_X && jj == 1) ? params.slice_nx : (jj - 1);
      y_n = (SINGLE_SLICE_Y) ? (ii % params.slice_ny) + 1 : (ii + 1);
      y_s = (SINGLE_SLICE_Y && ii == 1) ? params.slice_ny : (ii - 1);
      // TODO: THIS WILL DEFINITELY BREAK
      //Pre-calculate the adjacent cells to propagate to.
      adjacency[curr_cell].index[1] = ii * params.nx + x_e; // E
      adjacency[curr_cell].index[2] = y_n * params.nx + jj; // N
      adjacency[curr_cell].index[3] = ii * params.nx + x_w; // W
      adjacency[curr_cell].index[4] = y_s * params.nx + jj; // S
      adjacency[curr_cell].index[5] = y_n * params.nx + x_e; // NE
      adjacency[curr_cell].index[6] = y_n * params.nx + x_w; // NW
      adjacency[curr_cell].index[7] = y_s * params.nx + x_w; // SW
      adjacency[curr_cell].index[8] = y_s * params.nx + x_e; // SE
      for (int kk=1;kk<9;kk++) {
	if (adjacency[curr_cell].index[kk] < 0 || adjacency[curr_cell].index[kk] >+ params.slice_buff_len) {
	  printf("%d is out of range in rank %d in cell (%d,%d)\n", adjacency[curr_cell].index[kk], params.rank, jj, ii);
	  die("SHIIIIIIIIT\n",__LINE__,__FILE__);
	}
      }
    }
  }

  printf("out of prop_prep, %d\n", params.rank);
  return EXIT_SUCCESS;
}

int propagate(const t_param params, t_speed* cells, t_speed* tmp_cells, t_adjacency* adjacency)
{
  int curr_cell; // Stop re-calculating the array index repeatedly.

  /* loop over _all_ cells */
  for(curr_cell=params.slice_inner_start;curr_cell<params.slice_inner_end;++curr_cell) {
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

  printf("out of prop, %d\n", params.rank);
  return EXIT_SUCCESS;
}

int collision(const t_param params, t_speed* cells, t_speed* tmp_cells, int* obstacles)
{
  int kk;                         /* generic counters */
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
  const int cell_lim = params.slice_inner_end + 1; //TODO: We are wasting some work, but simplifying the loop. Should we unflatten the loop?

  /* loop over the cells in the grid
  ** NB the collision step is called after
  ** the propagate step and so values of interest
  ** are in the scratch-space grid */
  for(curr_cell=params.slice_inner_start;curr_cell<cell_lim;++curr_cell) {
      if(obstacles[curr_cell]) {
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

  printf("out of coll, %d\n", params.rank);
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

  // Each grid will now be split into smaller subsections. To make life easy, we will use row based chunks
  // that are simply row sized chunks of the larger array. We know that any access to higher indices than the current
  // rank must be to the following slice (as the interactions are only between neighbouring cells). Similar for lower.

  // Store all these values in our copy of params.
  // Set the slice length, rounded to a full row.
  params->slice_len = ((int)(params->ny / params->size)) * params->nx;

  if (params->slice_len * params->size != params->ny * params->nx) {
    die("cannot handle uneven slice divisions!",__LINE__,__FILE__);
  }

  // BEWARE: TODO: OMG: Above values are probably completely bogus and based on old assumptions.

  // Set the inner slice sizes.
  params->slice_nx = params->nx; // TODO: Support 2d slice grid.
  params->slice_ny = (int)(params->ny / params->size);

  // Total size of the buffer including exchange space.
  params->slice_buff_len = (params->slice_nx + 2) * (params->slice_ny + 2);

  // Want to know the index in a local sense for loops
  params->slice_inner_start = (params->slice_nx + 2) + 1; // ii (=1) * nx (=snx+2) + jj (=1)
  params->slice_inner_end = params->slice_ny * (params->slice_nx + 2) + params->slice_nx;
  // Start is obviously 0, with end being ((ny + 2) * (nx + 2)) - 1

  // Global index of the slice opening.
  params->slice_global_xs = 0;
  params->slice_global_ys = ((int)(params->ny / params->size)) * params->rank;
  params->slice_global_xe = params->slice_global_xs + params->slice_nx;
  params->slice_global_ye = params->slice_global_ys + params->slice_ny;

  {
    int r = 0;
    while (r < params->size) {
      if (params->rank == r) {
	printf("\n\nRank:%d\nSlice len:%d\nSlice nx:%d\nSlice global xs:%d\nSlice global xe:%d\nSlice ny:%d\nSlice global ys:%d\nSlice global ye:%d\nSlice inner start:%d\nSlice inner end:%d\nSlice buff len:%d\n\n", params->rank, params->slice_len, params->slice_nx, params->slice_global_xs, params->slice_global_xe, params->slice_ny, params->slice_global_ys, params->slice_global_ye, params->slice_inner_start, params->slice_inner_end, params->slice_buff_len);
      }
      r++;
      MPI_Barrier(MPI_COMM_WORLD);
    }
  }

  /* main grid */
  *cells_ptr = (t_speed*)malloc(sizeof(t_speed)*params->slice_buff_len);
  if (*cells_ptr == NULL) 
    die("cannot allocate memory for cells",__LINE__,__FILE__);

  /* 'helper' grid, used as scratch space */
  *tmp_cells_ptr = (t_speed*)malloc(sizeof(t_speed)*params->slice_buff_len);
  if (*tmp_cells_ptr == NULL) 
    die("cannot allocate memory for tmp_cells",__LINE__,__FILE__);

  /* the map of obstacles */
  *obstacles_ptr = malloc(sizeof(int*)*params->slice_len);
  if (*obstacles_ptr == NULL) 
    die("cannot allocate memory for obstacles",__LINE__,__FILE__);

  /* adjacency for propagate */
  *adjacency = malloc(sizeof(t_adjacency) * params->slice_len);
  if (*adjacency == NULL)
    die("cannot allocate adjacency memory",__LINE__,__FILE__);

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
      xx = xx - params->slice_global_xs + 1;
      yy = yy - params->slice_global_ys + 1;
      ii = (yy * (params->slice_nx + 2)) + xx;

      // Not particularly bullet proof, but an -ok- sanity check.
      if (ii > params->slice_inner_end || ii < params->slice_inner_start) {
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
	     int** obstacles_ptr, my_float** av_vels_ptr)
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

  return EXIT_SUCCESS;
}

my_float av_velocity(const t_param params, t_speed* cells, int* obstacles)
{
  int    kk,curr_cell;       /* generic counters */
  int    tot_cells = 0;  /* no. of cells used in calculation */
  my_float local_density;  /* total density in cell */
  my_float u_x;            /* x-component of velocity for current cell */
  my_float u_y;            /* y-component of velocity for current cell */
  my_float tot_u;          /* accumulated magnitudes of velocity for each cell */

  const int cell_lim = (params.ny * params.nx);

  /* initialise */
  tot_u = 0.0;

  /* loop over all non-blocked cells */
  for(curr_cell=0;curr_cell<cell_lim;++curr_cell) {
      /* ignore occupied cells */
    if(within_slice(params, curr_cell) && !obstacles[curr_cell]) {
	/* local density total */
	local_density = 0.0;
	for(kk=0;kk<NSPEEDS;kk++) {
	  local_density += cells[curr_cell].speeds[kk];
	}
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

  printf("out of av_vel, %d %f %d\n", params.rank, tot_u, tot_cells);
  MPI_Barrier(MPI_COMM_WORLD); //TODO: BYE BYE
  die("",0,"");
  return tot_u / (my_float)tot_cells;
}

my_float calc_reynolds(const t_param params, t_speed* cells, int* obstacles)
{
  const my_float viscosity = 1.0 / 6.0 * (2.0 / params.omega - 1.0);
  
  return av_velocity(params,cells,obstacles) * params.reynolds_dim / viscosity;
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
  FILE* fp;                     /* file pointer */
  int ii,jj,kk;                 /* generic counters */
  const double c_sq = 1.0/3.0;  /* sq. of speed of sound */
  double local_density;         /* per grid cell sum of densities */
  double pressure;              /* fluid pressure in grid cell */
  double u_x;                   /* x-component of velocity in grid cell */
  double u_y;                   /* y-component of velocity in grid cell */
  double u;                     /* norm--root of summed squares--of u_x and u_y */

  fp = fopen(FINALSTATEFILE,"w");
  if (fp == NULL) {
    die("could not open file output file",__LINE__,__FILE__);
  }

  for(ii=0;ii<params.ny;ii++) {
    for(jj=0;jj<params.nx;jj++) {
      /* an occupied cell */
      if(obstacles[ii*params.nx + jj]) {
	u_x = u_y = u = 0.0;
	pressure = params.density * c_sq;
      }
      /* no obstacle */
      else {
	local_density = 0.0;
	for(kk=0;kk<NSPEEDS;kk++) {
	  local_density += cells[ii*params.nx + jj].speeds[kk];
	}
	/* compute x velocity component */
	u_x = (cells[ii*params.nx + jj].speeds[1] + 
	       cells[ii*params.nx + jj].speeds[5] +
	       cells[ii*params.nx + jj].speeds[8]
	       - (cells[ii*params.nx + jj].speeds[3] + 
		  cells[ii*params.nx + jj].speeds[6] + 
		  cells[ii*params.nx + jj].speeds[7]))
	  / local_density;
	/* compute y velocity component */
	u_y = (cells[ii*params.nx + jj].speeds[2] + 
	       cells[ii*params.nx + jj].speeds[5] + 
	       cells[ii*params.nx + jj].speeds[6]
	       - (cells[ii*params.nx + jj].speeds[4] + 
		  cells[ii*params.nx + jj].speeds[7] + 
		  cells[ii*params.nx + jj].speeds[8]))
	  / local_density;
	/* compute norm of velocity */
	u = my_sqrt((u_x * u_x) + (u_y * u_y));
	/* compute pressure */
	pressure = local_density * c_sq;
      }
      /* write to file */
      fprintf(fp,"%d %d %.12E %.12E %.12E %.12E %d\n",jj,ii,u_x,u_y,u,pressure,obstacles[ii*params.nx + jj]);
    }
  }

  fclose(fp);

  fp = fopen(AVVELSFILE,"w");
  if (fp == NULL) {
    die("could not open file output file",__LINE__,__FILE__);
  }
  for (ii=0;ii<params.maxIters;ii++) {
    fprintf(fp,"%d:\t%.12E\n", ii, (double)av_vels[ii]);
  }

  fclose(fp);

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

/* inline int slice_index(const t_param params, const int index) */
/* { */
/*   return index - params.slice_start; */
/* } */

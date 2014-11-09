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
#include<string.h>

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

/* struct to hold the parameter values */
typedef struct {
  int    nx;            /* no. of cells in x-direction */
  int    ny;            /* no. of cells in y-direction */
  int    maxIters;      /* no. of iterations */
  int    reynolds_dim;  /* dimension for Reynolds number */
  my_float density;       /* density per link */
  my_float accel;         /* density redistribution */
  my_float omega;         /* relaxation parameter */
} t_param;

// struct to hold adjacency values.
typedef struct {
  unsigned int index[NSPEEDS];
} t_adjacency;

enum boolean { FALSE, TRUE };

/*
** function prototypes
*/

/* load params, allocate memory, load obstacles & initialise fluid particle densities */
int initialise(const char* paramfile, const char* obstaclefile,
	       t_param* params, my_float*** cells_ptr, my_float*** tmp_cells_ptr, 
	       int** obstacles_ptr, my_float** av_vels_ptr, t_adjacency** adjacency);

/* 
** The main calculation methods.
** timestep calls, in order, the functions:
** accelerate_flow(), propagate(), rebound() & collision()
*/
int timestep(const t_param params, my_float *const restrict *const restrict cells, my_float *const restrict *const restrict tmp_cells, int* obstacles, t_adjacency* adjacency);
int accelerate_flow(const t_param params, my_float *const restrict *const restrict cells, int* obstacles);
void propagate_prep(const t_param params, t_adjacency* adjacency);
int propagate(const t_param params, my_float *const restrict *const restrict cells, my_float *const restrict *const restrict tmp_cells, t_adjacency* adjacency);
int collision(const t_param params, my_float *const restrict *const restrict cells, my_float *const restrict *const restrict tmp_cells, int* obstacles);
int write_values(const t_param params, my_float *const restrict *const restrict cells, int* obstacles, my_float* av_vels);

/* finalise, including freeing up allocated memory */
int finalise(const t_param* params, my_float*** cells_ptr, my_float*** tmp_cells_ptr,
	     int** obstacles_ptr, my_float** av_vels_ptr);

/* Sum all the densities in the grid.
** The total should remain constant from one timestep to the next. */
my_float total_density(const t_param params, my_float *const restrict *const restrict cells);

/* compute average velocity */
my_float av_velocity(const t_param params, my_float *const restrict *const restrict cells, int* obstacles);

/* calculate Reynolds number */
my_float calc_reynolds(const t_param params, my_float *const restrict *const restrict cells, int* obstacles);

/* utility functions */
void die(const char* message, const int line, const char *file);
void usage(const char* exe);

/*
** main program:
** initialise, timestep loop, finalise
*/
int main(int argc, char* argv[])
{
  char*    paramfile = NULL;     /* name of the input parameter file */
  char*    obstaclefile = NULL;  /* name of a the input obstacle file */
  t_param  params;               /* struct to hold parameter values */
  my_float** cells     = NULL;   /* grid containing fluid densities */
  my_float** tmp_cells = NULL;   /* scratch space */
  int*     obstacles = NULL;     /* grid indicating which cells are blocked */
  my_float*  av_vels   = NULL;   /* a record of the av. velocity computed for each timestep */
  int      ii;                   /* generic counter */
  struct timeval timstr;         /* structure to hold elapsed time */
  struct rusage ru;              /* structure to hold CPU time--system and user */
  double tic,toc;                /* floating point numbers to calculate elapsed wallclock time */
  double usrtim;                 /* floating point number to record elapsed user CPU time */
  double systim;                 /* floating point number to record elapsed system CPU time */
  t_adjacency* adjacency = NULL; /* store adjacency for each cell in each direction for propagate. */

  /* parse the command line */
  if(argc != 3) {
    usage(argv[0]);
  }
  else{
    paramfile = argv[1];
    obstaclefile = argv[2];
  }

  /* initialise our data structures and load values from file */
  initialise(paramfile, obstaclefile, &params, &cells, &tmp_cells, &obstacles, &av_vels, &adjacency);

  /* iterate for maxIters timesteps */
  gettimeofday(&timstr,NULL);
  tic=timstr.tv_sec+(timstr.tv_usec/1000000.0);

  // Can we do this outside the timing? Probably not!
  propagate_prep(params, adjacency);

  for (ii=0;ii<params.maxIters;ii++) {
    timestep(params,cells,tmp_cells,obstacles, adjacency);
    av_vels[ii] = av_velocity(params,cells,obstacles);
#ifdef DEBUG
    printf("==timestep: %d==\n",ii);
    printf("av velocity: %.12E\n", av_vels[ii]);
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
  printf("==done==\n");
  printf("Reynolds number:\t\t%.12E\n",(double)calc_reynolds(params,cells,obstacles));
  printf("Elapsed time:\t\t\t%.6lf (s)\n", toc-tic);
  printf("Elapsed user CPU time:\t\t%.6lf (s)\n", usrtim);
  printf("Elapsed system CPU time:\t%.6lf (s)\n", systim);
  write_values(params,cells,obstacles,av_vels);
  finalise(&params, &cells, &tmp_cells, &obstacles, &av_vels);
  
  return EXIT_SUCCESS;
}

int timestep(const t_param params, my_float *const restrict *const restrict cells, my_float *const restrict *const restrict tmp_cells, int* obstacles, t_adjacency* adjacency)
{
  accelerate_flow(params,cells,obstacles);
  propagate(params,cells,tmp_cells, adjacency);
  collision(params,cells,tmp_cells,obstacles);
  return EXIT_SUCCESS; 
}

int accelerate_flow(const t_param params, my_float *const restrict *const restrict cells, int* obstacles)
{
  int ii,jj;     /* generic counters */
  my_float w1,w2;  /* weighting factors */
  
  /* compute weighting factors */
  w1 = params.density * params.accel / 9.0;
  w2 = params.density * params.accel / 36.0;

  /* modify the 2nd row of the grid */
  ii=params.ny - 2;
  for(jj=0;jj<params.nx;jj++) {
    /* if the cell is not occupied and
    ** we don't send a density negative */
    if( !obstacles[ii*params.nx + jj] && 
	(cells[3][ii*params.nx + jj] - w1) > 0.0 &&
	(cells[6][ii*params.nx + jj] - w2) > 0.0 &&
	(cells[7][ii*params.nx + jj] - w2) > 0.0 ) {
      /* increase 'east-side' densities */
      cells[1][ii*params.nx + jj] += w1;
      cells[5][ii*params.nx + jj] += w2;
      cells[8][ii*params.nx + jj] += w2;
      /* decrease 'west-side' densities */
      cells[3][ii*params.nx + jj] -= w1;
      cells[6][ii*params.nx + jj] -= w2;
      cells[7][ii*params.nx + jj] -= w2;
    }
  }

  return EXIT_SUCCESS;
}


void propagate_prep(const t_param params, t_adjacency* adjacency)
{
  int ii,jj;            /* generic counters */
  int x_e,x_w,y_n,y_s;  /* indices of neighbouring cells */

  /* loop over _all_ cells */
  for(ii=0;ii<params.ny;ii++) {
    for(jj=0;jj<params.nx;jj++) {
      /* determine indices of axis-direction neighbours
      ** respecting periodic boundary conditions (wrap around) */
      y_n = (ii + 1) % params.ny;
      x_e = (jj + 1) % params.nx;
      y_s = (ii == 0) ? (ii + params.ny - 1) : (ii - 1);
      x_w = (jj == 0) ? (jj + params.nx - 1) : (jj - 1);
      // Pre-calculate the adjacent cells to propagate to.
      //adjacency[ii*params.nx + jj].index[0] = ii * params.nx + jj; // Centre TODO: Ignore?
      adjacency[ii*params.nx + jj].index[1] = ii * params.nx + x_e; // N
      adjacency[ii*params.nx + jj].index[2] = y_n * params.nx + jj; // E
      adjacency[ii*params.nx + jj].index[3] = ii * params.nx + x_w; // W
      adjacency[ii*params.nx + jj].index[4] = y_s * params.nx + jj; // S
      adjacency[ii*params.nx + jj].index[5] = y_n * params.nx + x_e; // NE
      adjacency[ii*params.nx + jj].index[6] = y_n * params.nx + x_w; // NW
      adjacency[ii*params.nx + jj].index[7] = y_s * params.nx + x_w; // SW
      adjacency[ii*params.nx + jj].index[8] = y_s * params.nx + x_e; // SE
    }
  }
}

int propagate(const t_param params, my_float *const restrict *const restrict cells, my_float *const restrict *const restrict tmp_cells, t_adjacency* adjacency)
{
  int curr_cell; // Stop re-calculating the array index repeatedly.
  const int cell_lim = (params.ny * params.nx);

  // The 0 values will always be the same, simple copy.
  memcpy(tmp_cells[0], cells[0], sizeof(my_float) * (params.nx*params.ny));

  /* loop over _all_ cells */
  for(curr_cell=0;curr_cell<cell_lim;++curr_cell) {
    /* propagate densities to neighbouring cells, following
    ** appropriate directions of travel and writing into
    ** scratch space grid */
    tmp_cells[1][adjacency[curr_cell].index[1]] = cells[1][curr_cell]; /* east */
    tmp_cells[2][adjacency[curr_cell].index[2]] = cells[2][curr_cell]; /* north */
    tmp_cells[3][adjacency[curr_cell].index[3]] = cells[3][curr_cell]; /* west */
    tmp_cells[4][adjacency[curr_cell].index[4]] = cells[4][curr_cell]; /* south */
    tmp_cells[5][adjacency[curr_cell].index[5]] = cells[5][curr_cell]; /* north-east */
    tmp_cells[6][adjacency[curr_cell].index[6]] = cells[6][curr_cell]; /* north-west */
    tmp_cells[7][adjacency[curr_cell].index[7]] = cells[7][curr_cell]; /* south-west */
    tmp_cells[8][adjacency[curr_cell].index[8]] = cells[8][curr_cell]; /* south-east */
  }

  return EXIT_SUCCESS;
}

int collision(const t_param params, my_float *const restrict *const restrict cells, my_float *const restrict *const restrict tmp_cells, int* obstacles)
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
  const int cell_lim = (params.ny * params.nx);

  /* loop over the cells in the grid
  ** NB the collision step is called after
  ** the propagate step and so values of interest
  ** are in the scratch-space grid */
  for(curr_cell=0;curr_cell<cell_lim;++curr_cell) {
      if(obstacles[curr_cell]) {
	/* called after propagate, so taking values from scratch space
	** mirroring, and writing into main grid */
	cells[1][curr_cell] = tmp_cells[3][curr_cell];
	cells[2][curr_cell] = tmp_cells[4][curr_cell];
	cells[3][curr_cell] = tmp_cells[1][curr_cell];
	cells[4][curr_cell] = tmp_cells[2][curr_cell];
	cells[5][curr_cell] = tmp_cells[7][curr_cell];
	cells[6][curr_cell] = tmp_cells[8][curr_cell];
	cells[7][curr_cell] = tmp_cells[5][curr_cell];
	cells[8][curr_cell] = tmp_cells[6][curr_cell];
      } else {
	/* don't consider occupied cells */
	/* compute local density total */
	local_density = 0.0;
	for(kk=0;kk<NSPEEDS;kk++) {
	  local_density += tmp_cells[kk][curr_cell];
	}

	/* compute x velocity component */
	u_x = (tmp_cells[1][curr_cell] + 
	       tmp_cells[5][curr_cell] + 
	       tmp_cells[8][curr_cell]
	       - (tmp_cells[3][curr_cell] + 
		  tmp_cells[6][curr_cell] + 
		  tmp_cells[7][curr_cell]))
	  / local_density;

	/* compute y velocity component */
	u_y = (tmp_cells[2][curr_cell] + 
	       tmp_cells[5][curr_cell] + 
	       tmp_cells[6][curr_cell]
	       - (tmp_cells[4][curr_cell] + 
		  tmp_cells[7][curr_cell] + 
		  tmp_cells[8][curr_cell]))
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
	  cells[kk][curr_cell] = (tmp_cells[kk][curr_cell]
				  + params.omega * 
				  (d_equ[kk] - tmp_cells[kk][curr_cell]));
	}
    }
  }

  return EXIT_SUCCESS; 
}

int initialise(const char* paramfile, const char* obstaclefile,
	       t_param* params, my_float*** cells_ptr, my_float*** tmp_cells_ptr, 
	       int** obstacles_ptr, my_float** av_vels_ptr, t_adjacency** adjacency)
{
  char   message[1024];  /* message buffer */
  FILE   *fp;            /* file pointer */
  int    ii,jj;          /* generic counters */
  int    xx,yy;          /* generic array indices */
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

  /* main grid */
  // Allocate the outer array of NSPEEDS.
  *cells_ptr     = malloc(sizeof(my_float *) * NSPEEDS);
  *tmp_cells_ptr = malloc(sizeof(my_float *) * NSPEEDS);
  if (*cells_ptr == NULL) 
    die("cannot allocate memory for cells (outer)",__LINE__,__FILE__);
  if (*tmp_cells_ptr == NULL) 
    die("cannot allocate memory for tmp_cells (outer)",__LINE__,__FILE__);
  // Allocate each inner array for the size of the problem space.
  for (ii = 0; ii < NSPEEDS; ii++) {
    (*cells_ptr)[ii]     = malloc(sizeof(my_float) * (params->ny*params->nx));
    (*tmp_cells_ptr)[ii] = malloc(sizeof(my_float) * (params->ny*params->nx));
    if ((*cells_ptr)[ii] == NULL) 
      die("cannot allocate memory for cells (inner)",__LINE__,__FILE__);
    if ((*tmp_cells_ptr)[ii] == NULL) 
      die("cannot allocate memory for cells (inner)",__LINE__,__FILE__);
  }

  /* the map of obstacles */
  *obstacles_ptr = malloc(sizeof(int*)*(params->ny*params->nx));
  if (*obstacles_ptr == NULL) 
    die("cannot allocate column memory for obstacles",__LINE__,__FILE__);

  /* adjacency for propagate */
  *adjacency = malloc(sizeof(t_adjacency) * (params->ny*params->nx));
  if (*adjacency == NULL)
    die("cannot allocate adjacency memory",__LINE__,__FILE__);

  /* initialise densities */
  w0 = params->density * 4.0/9.0;
  w1 = params->density      /9.0;
  w2 = params->density      /36.0;

  for(ii=0;ii<params->ny;ii++) {
    for(jj=0;jj<params->nx;jj++) {
      /* centre */
      (*cells_ptr)[0][ii*params->nx + jj] = w0;
      /* axis directions */
      (*cells_ptr)[1][ii*params->nx + jj] = w1;
      (*cells_ptr)[2][ii*params->nx + jj] = w1;
      (*cells_ptr)[3][ii*params->nx + jj] = w1;
      (*cells_ptr)[4][ii*params->nx + jj] = w1;
      /* diagonals */
      (*cells_ptr)[5][ii*params->nx + jj] = w2;
      (*cells_ptr)[6][ii*params->nx + jj] = w2;
      (*cells_ptr)[7][ii*params->nx + jj] = w2;
      (*cells_ptr)[8][ii*params->nx + jj] = w2;

      /* (Merge following loop) set all cells in obstacle array to zero */ 
      (*obstacles_ptr)[ii*params->nx + jj] = 0;
    }
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
    /* assign to array */
    (*obstacles_ptr)[yy*params->nx + xx] = blocked;
  }
  
  /* and close the file */
  fclose(fp);

  /* 
  ** allocate space to hold a record of the average velocities computed 
  ** at each timestep
  */
  *av_vels_ptr = (my_float*)malloc(sizeof(my_float)*params->maxIters);

  return EXIT_SUCCESS;
}

int finalise(const t_param* params, my_float*** cells_ptr, my_float*** tmp_cells_ptr,
	     int** obstacles_ptr, my_float** av_vels_ptr)
{
  /* 
  ** free up allocated memory
  */
  // TODO: Need to free the extra arrays!
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

my_float av_velocity(const t_param params, my_float *const restrict *const restrict cells, int* obstacles)
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
      if(!obstacles[curr_cell]) {
	/* local density total */
	local_density = 0.0;
	for(kk=0;kk<NSPEEDS;kk++) {
	  local_density += cells[kk][curr_cell];
	}
	/* x-component of velocity */
	u_x = (cells[1][curr_cell] + 
		    cells[5][curr_cell] + 
		    cells[8][curr_cell]
		    - (cells[3][curr_cell] + 
		       cells[6][curr_cell] + 
		       cells[7][curr_cell])) / 
	  local_density;
	/* compute y velocity component */
	u_y = (cells[2][curr_cell] + 
		    cells[5][curr_cell] + 
		    cells[6][curr_cell]
		    - (cells[4][curr_cell] + 
		       cells[7][curr_cell] + 
		       cells[8][curr_cell])) /
	  local_density;
	/* accumulate the norm of x- and y- velocity components */
	tot_u += my_sqrt((u_x * u_x) + (u_y * u_y));
	/* increase counter of inspected cells */
	++tot_cells;
    }
  }

  return tot_u / (my_float)tot_cells;
}

my_float calc_reynolds(const t_param params, my_float *const restrict *const restrict cells, int* obstacles)
{
  const my_float viscosity = 1.0 / 6.0 * (2.0 / params.omega - 1.0);
  
  return av_velocity(params,cells,obstacles) * params.reynolds_dim / viscosity;
}

my_float total_density(const t_param params, my_float *const restrict *const restrict cells)
{
  int ii,jj,kk;        /* generic counters */
  my_float total = 0.0;  /* accumulator */

  for(ii=0;ii<params.ny;ii++) {
    for(jj=0;jj<params.nx;jj++) {
      for(kk=0;kk<NSPEEDS;kk++) {
	total += cells[kk][ii*params.nx + jj];
      }
    }
  }

  return total;
}

int write_values(const t_param params, my_float *const restrict *const restrict cells, int* obstacles, my_float* av_vels)
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
	  local_density += cells[kk][ii*params.nx + jj];
	}
	/* compute x velocity component */
	u_x = (cells[1][ii*params.nx + jj] + 
	       cells[5][ii*params.nx + jj] +
	       cells[8][ii*params.nx + jj]
	       - (cells[3][ii*params.nx + jj] + 
		  cells[6][ii*params.nx + jj] + 
		  cells[7][ii*params.nx + jj]))
	  / local_density;
	/* compute y velocity component */
	u_y = (cells[2][ii*params.nx + jj] + 
	       cells[5][ii*params.nx + jj] + 
	       cells[6][ii*params.nx + jj]
	       - (cells[4][ii*params.nx + jj] + 
		  cells[7][ii*params.nx + jj] + 
		  cells[8][ii*params.nx + jj]))
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
  exit(EXIT_FAILURE);
}

void usage(const char* exe)
{
  fprintf(stderr, "Usage: %s <paramfile> <obstaclefile>\n", exe);
  exit(EXIT_FAILURE);
}

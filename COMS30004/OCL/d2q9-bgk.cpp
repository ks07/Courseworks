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

#ifndef LOCAL_SIZE
#define LWGS1 cl::NullRange
//#define LWGS1 128
#else
#define LWGS1 cl::NDRange(LOCAL_SIZE)
#endif

#ifndef REDUCTION_SIZE
//#define URS 2
#define URS 16
#else
#define URS REDUCTION_SIZE
#endif

#ifndef FINAL_R_SIZE
#define FRS cl::NullRange
#define FRS_PAD_TO 1
#else
#define FRS FINAL_R_SIZE
#define FRS_PAD_TO FINAL_R_SIZE
#endif

#define __CL_ENABLE_EXCEPTIONS

#include<cmath>
#include<cstdio>
#include<cstdlib>
#include<ctime>
#include<sys/time.h>
#include<sys/resource.h>
#include<vector>
#include<iostream>
#include<CL/cl.hpp>
#include "util.hpp"
#include "device_picker.hpp"
#include "err_code.h"

#define NSPEEDS         9
#define FINALSTATEFILE  "final_state.dat"
#define AVVELSFILE      "av_vels.dat"

typedef cl_float my_float;
#define my_sqrt sqrtf
#define MY_FLOAT_PATTERN "%f\n"

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

/*
** function prototypes
*/

/* load params, allocate memory, load obstacles & initialise fluid particle densities */
int initialise(const char* paramfile, const char* obstaclefile, t_param* params, std::vector<my_float>** cells_ptr,
	       std::vector<my_float>** tmp_cells_ptr, std::vector<cl_char>** obstacles_ptr, unsigned int &obstacle_count,
	       std::vector<cl_uint>** adjacency);

/* 
** The main calculation methods.
** timestep calls, in order, the functions:
** accelerate_flow(), propagate(), rebound() & collision()
*/
int write_values(const t_param params, std::vector<my_float> &cells, std::vector<cl_char> &obstacles, std::vector<my_float> &av_vels, const unsigned int nwork_groups);

/* finalise, including freeing up allocated memory */
//TODO: Fix finalise
//int finalise(const t_param* params, my_float** cells_ptr, my_float** tmp_cells_ptr,
//	     int** obstacles_ptr, my_float** av_vels_ptr);

/* Sum all the densities in the grid.
** The total should remain constant from one timestep to the next. */
my_float total_density(const t_param params, std::vector<my_float> &cells);

/* compute average velocity */
//my_float av_velocity(const t_param params, std::vector<my_float> &cells, std::vector<int> &obstacles);

/* calculate Reynolds number */
my_float calc_reynolds(const t_param params, std::vector<my_float> &cells, std::vector<cl_char> &obstacles);

/* utility functions */
void die(const char* message, const int line, const char *file);
void usage(const char* exe);

void init_context_bcp3(cl::Context& context, cl::Device& device);

/*
** main program:
** initialise, timestep loop, finalise
*/
int main(int argc, char* argv[])
{
  char*    paramfile = NULL;    /* name of the input parameter file */
  char*    obstaclefile = NULL; /* name of a the input obstacle file */
  t_param  params;              /* struct to hold parameter values */
  std::vector<my_float>* cells     = NULL;    /* grid containing fluid densities */
  std::vector<my_float>* tmp_cells = NULL;    /* scratch space */
  std::vector<cl_char>*     obstacles = NULL;    /* grid indicating which cells are blocked */
  std::vector<my_float>  partial_tot_u; // a record of the av. velocity computed for each timestep
  int      ii;                  /* generic counter */
  struct timeval timstr;        /* structure to hold elapsed time */
  struct rusage ru;             /* structure to hold CPU time--system and user */
  double tic,toc;               /* floating point numbers to calculate elapsed wallclock time */
  double usrtim;                /* floating point number to record elapsed user CPU time */
  double systim;                /* floating point number to record elapsed system CPU time */
  std::vector<cl_uint>* adjacency = NULL; /* store adjacency for each cell in each direction for propagate. */
  unsigned int obstacle_count = 0;

  cl::Context context;
  cl::Device device;
  std::string name;

  /* parse the command line */
  if(argc < 3) {
    usage(argv[0]);
  } else if (argc == 3) {
    paramfile = argv[1];
    obstaclefile = argv[2];
    init_context_bcp3(context, device);
  } else {
    // OpenCL setup. From HandsOnOpenCL
    cl_uint deviceIndex = 0;
    std::vector<cl::Device> devices;
    unsigned numDevices = getDeviceList(devices);

    if (deviceIndex >= numDevices) {
      std::cout << "Invalid device index (try '--list')\n";
      return EXIT_FAILURE;
    }

    parseArguments(argc, argv, &deviceIndex);
    device = devices[deviceIndex];

    std::vector<cl::Device> chosen_device;
    chosen_device.push_back(device);
    context = cl::Context(chosen_device);

    paramfile = argv[1];
    obstaclefile = argv[2];
  }
  
  getDeviceName(device, name);
  std::cout << "Using OpenCL device: " << name << "\n";

  cl::CommandQueue queue(context, device);

  /* initialise our data structures and load values from file */
  initialise(paramfile, obstaclefile, &params, &cells, &tmp_cells, &obstacles, obstacle_count, &adjacency);

  // Read in and compile OpenCL kernels
  cl::Program clprog_propagate_prep(context, util::loadProgram("./propagate_prep.cl"), false);
  cl::Program clprog_collision(context, util::loadProgram("./collision.cl"), false);
  cl::Program clprog_propagate(context, util::loadProgram("./propagate.cl"), false);
  cl::Program clprog_accelerate_flow(context, util::loadProgram("./accelerate_flow.cl"), false);
  cl::Program clprog_av_velocity(context, util::loadProgram("./av_velocity.cl"), false);
  cl::Program clprog_final_reduce(context, util::loadProgram("./final_reduce.cl"), false);

  try {
    std::cout << "Beginning kernel build..." << std::endl;

    clprog_propagate_prep.build("-cl-single-precision-constant -cl-denorms-are-zero -cl-strict-aliasing -cl-mad-enable -cl-no-signed-zeros -cl-fast-relaxed-math");
    clprog_collision.build("-cl-single-precision-constant -cl-denorms-are-zero -cl-strict-aliasing -cl-mad-enable -cl-no-signed-zeros -cl-fast-relaxed-math");
    clprog_propagate.build("-cl-single-precision-constant -cl-denorms-are-zero -cl-strict-aliasing -cl-mad-enable -cl-no-signed-zeros -cl-fast-relaxed-math");
    clprog_accelerate_flow.build("-cl-single-precision-constant -cl-denorms-are-zero -cl-strict-aliasing -cl-mad-enable -cl-no-signed-zeros -cl-fast-relaxed-math");
    clprog_av_velocity.build("-cl-single-precision-constant -cl-denorms-are-zero -cl-strict-aliasing -cl-mad-enable -cl-no-signed-zeros -cl-fast-relaxed-math");
    clprog_final_reduce.build("-cl-single-precision-constant -cl-denorms-are-zero -cl-strict-aliasing -cl-mad-enable -cl-no-signed-zeros -cl-fast-relaxed-math");
    
    std::cout << "Kernel build complete" << std::endl;

    // Set variables to divide work in reduction.
    ::size_t nwork_groups;
    ::size_t work_group_size = 8;
    const ::size_t unit_length = URS;

    // Reduction kernels are usually expecting power of 2 dimensions. This is also good, because for whatever reason
    // KERNEL_WORK_GROUP_SIZE seems to have a thing for powers of 2. Round up to the nearest 
    ::size_t padded_prob_size = pow(2, ceil(log(params.nx*params.ny) / log(2)));

    // Find a padded size to try the final reduce as a multiple of preferred size (32).
    ::size_t padded_fred_size = params.maxIters + (FRS_PAD_TO - params.maxIters % FRS_PAD_TO);

    std::cout << "Padded problem size for reduction is: " << padded_prob_size << std::endl;

    // Get kernel object to query information
    cl::Kernel ko_av_velocity(clprog_av_velocity, "av_velocity");
    work_group_size = ko_av_velocity.getWorkGroupInfo<CL_KERNEL_WORK_GROUP_SIZE>(device);
    // From the work_group_size (the number of workers per group), problem size, and a constant work unit size
    // we can calculate the number of work groups needed.
    nwork_groups = padded_prob_size / (work_group_size*unit_length);

    printf(
	   " %d work groups of size %d.  %ld Integration steps\n",
	   (int)nwork_groups,
	   (int)work_group_size,
	   work_group_size*unit_length*nwork_groups);

    // Need to check the edge case where we have a tiny problem with big compute device.
    if (nwork_groups < 1) {
      // This case is just broken? No attempt at actually dividing the problem space evenly?
      std::cout << "WTF" << std::endl;
      nwork_groups = device.getInfo<CL_DEVICE_MAX_COMPUTE_UNITS>(); // Reset the groups to the number of compute units. (So 1 WG on 1 core)
      work_group_size = padded_prob_size / (nwork_groups*unit_length); // Reset the work group size to fit the new group count.
    }

    printf(
	   " %d work groups of size %d.  %ld Integration steps\n",
	   (int)nwork_groups,
	   (int)work_group_size,
	   work_group_size*unit_length*nwork_groups);

    // Vector on host so we can sum the partial sums ourselves.
    partial_tot_u.resize(nwork_groups * params.maxIters);

    cl::make_kernel<cl::Buffer> cl_propagate_prep(clprog_propagate_prep, "propagate_prep");
    cl::make_kernel<my_float, cl::Buffer, cl::Buffer, cl::Buffer> cl_collision(clprog_collision, "collision");
    cl::make_kernel<cl::Buffer, cl::Buffer, cl::Buffer> cl_propagate(clprog_propagate, "propagate");
    cl::make_kernel<t_param, cl::Buffer, cl::Buffer> cl_accelerate_flow(clprog_accelerate_flow, "accelerate_flow");
    cl::make_kernel<int, int, cl::Buffer, cl::Buffer, cl::LocalSpaceArg, cl::Buffer, int> cl_av_velocity(clprog_av_velocity, "av_velocity");
    cl::make_kernel<int, int, cl::Buffer, int> cl_final_reduce(clprog_final_reduce, "final_reduce");

    // Create OpenCL buffer TODO: Don't bother with this copy operation and keep fully on device... or copy to constant memory?
    cl::Buffer cl_adjacency = cl::Buffer(context, CL_MEM_READ_WRITE, sizeof(cl_uint) * params.nx * params.ny * NSPEEDS);
    cl::Buffer cl_cells = cl::Buffer(context, cells->begin(), cells->end(), false);
    cl::Buffer cl_tmp_cells = cl::Buffer(context, tmp_cells->begin(), tmp_cells->end(), false);
    cl::Buffer cl_obstacles = cl::Buffer(context, obstacles->begin(), obstacles->end(), true);
    cl::Buffer cl_round_tot_u = cl::Buffer(context, CL_MEM_READ_WRITE, sizeof(cl_float) * nwork_groups * params.maxIters); // Buffer to hold partial sums for reduction.
    cl_propagate_prep(cl::EnqueueArgs(queue, cl::NDRange(params.ny, params.nx)), cl_adjacency);

    // End OpenCL operations
    queue.finish();

    std::cout << "Trundling into the timestep loop." << std::endl;

    /* iterate for maxIters timesteps */
    gettimeofday(&timstr,NULL);
    tic=timstr.tv_sec+(timstr.tv_usec/1000000.0);

    for (ii=0;ii<params.maxIters;ii++) {
      cl_accelerate_flow(cl::EnqueueArgs(queue, cl::NDRange(params.nx), LWGS1), params, cl_cells, cl_obstacles);
      cl_propagate(cl::EnqueueArgs(queue, cl::NDRange(params.ny*params.nx), LWGS1), cl_cells, cl_tmp_cells, cl_adjacency);
      cl_collision(cl::EnqueueArgs(queue, cl::NDRange(params.ny*params.nx), LWGS1), params.omega, cl_cells, cl_tmp_cells, cl_obstacles);
      cl_av_velocity(cl::EnqueueArgs(queue, cl::NDRange(padded_prob_size/unit_length), cl::NDRange(work_group_size)), params.nx*params.ny, unit_length, cl_cells, cl_obstacles, cl::Local(sizeof(cl_float) * work_group_size), cl_round_tot_u, ii);
    }

    cl_final_reduce(cl::EnqueueArgs(queue, cl::NDRange(padded_fred_size), FRS), nwork_groups, (params.ny*params.nx - obstacle_count), cl_round_tot_u, params.maxIters);
    queue.finish();
    // Copy the partial sums off the device
    cl::copy(queue, cl_round_tot_u, partial_tot_u.begin(), partial_tot_u.end());
    cl::copy(queue, cl_cells, cells->begin(), cells->end());

    gettimeofday(&timstr,NULL);
    toc=timstr.tv_sec+(timstr.tv_usec/1000000.0);
    getrusage(RUSAGE_SELF, &ru);
    timstr=ru.ru_utime;        
    usrtim=timstr.tv_sec+(timstr.tv_usec/1000000.0);
    timstr=ru.ru_stime;        
    systim=timstr.tv_sec+(timstr.tv_usec/1000000.0);

    /* write final values and free memory */
    printf("==done==\n");
    printf("Reynolds number:\t\t%.12E\n",(double)calc_reynolds(params,*cells,*obstacles));
    printf("Elapsed time:\t\t\t%.6lf (s)\n", toc-tic);
    printf("Elapsed user CPU time:\t\t%.6lf (s)\n", usrtim);
    printf("Elapsed system CPU time:\t%.6lf (s)\n", systim);
    write_values(params,*cells,*obstacles,partial_tot_u,nwork_groups);
    //  finalise(&params, &cells, &tmp_cells, &obstacles, &av_vels);  

  } catch (cl::Error &err) {
    std::cout << "Exception" << std::endl;
    std::cerr << err.what() << "(" << err_code(err.err()) << ")" << std::endl; 
    std::string blog = clprog_propagate.getBuildInfo<CL_PROGRAM_BUILD_LOG>(device);
    std::cerr << blog << std::endl;

    return EXIT_FAILURE;
  }

  return EXIT_SUCCESS;
}

int initialise(const char* paramfile, const char* obstaclefile,
	       t_param* params, std::vector<my_float>** cells_ptr, std::vector<my_float>** tmp_cells_ptr, 
	       std::vector<cl_char>** obstacles_ptr, unsigned int &obstacle_count, std::vector<cl_uint>** adjacency)
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
  *cells_ptr = new std::vector<my_float>(params->ny*params->nx*NSPEEDS);

  /* 'helper' grid, used as scratch space */
  *tmp_cells_ptr = new std::vector<my_float>(params->ny*params->nx*NSPEEDS);
  
  /* the map of obstacles */
  *obstacles_ptr = new std::vector<cl_char>(params->ny*params->nx);

  /* adjacency for propagate */
  *adjacency = new std::vector<cl_uint>(params->ny*params->nx*NSPEEDS);

  /* initialise densities */
  w0 = params->density * 4.0/9.0;
  w1 = params->density      /9.0;
  w2 = params->density      /36.0;

  for(ii=0;ii<params->ny;ii++) {
    for(jj=0;jj<params->nx;jj++) {
      /* centre */
      //(**cells_ptr)[ii*params->nx + jj].speeds[0] = w0;
      (**cells_ptr)[0*params->nx*params->ny + ii*params->nx + jj] = w0;
      /* axis directions */
      (**cells_ptr)[1*params->nx*params->ny + ii*params->nx + jj] = w1;
      (**cells_ptr)[2*params->nx*params->ny + ii*params->nx + jj] = w1;
      (**cells_ptr)[3*params->nx*params->ny + ii*params->nx + jj] = w1;
      (**cells_ptr)[4*params->nx*params->ny + ii*params->nx + jj] = w1;
      /* diagonals */
      (**cells_ptr)[5*params->nx*params->ny + ii*params->nx + jj] = w2;
      (**cells_ptr)[6*params->nx*params->ny + ii*params->nx + jj] = w2;
      (**cells_ptr)[7*params->nx*params->ny + ii*params->nx + jj] = w2;
      (**cells_ptr)[8*params->nx*params->ny + ii*params->nx + jj] = w2;
    }
  }

  /* first set all cells in obstacle array to zero */ 
  for(ii=0;ii<params->ny;ii++) {
    for(jj=0;jj<params->nx;jj++) {
      (**obstacles_ptr)[ii*params->nx + jj] = 0;
    }
  }

  obstacle_count = 0;

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
    // if not already blocked, add to count. This check is not strictly necessary.
    if ((**obstacles_ptr)[yy*params->nx + xx] != 1) {
      obstacle_count++;
    }
    /* assign to array */
    (**obstacles_ptr)[yy*params->nx + xx] = blocked;
  }
  
  /* and close the file */
  fclose(fp);

  return EXIT_SUCCESS;
}

int finalise(const t_param* params, my_float** cells_ptr, my_float** tmp_cells_ptr,
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

my_float av_velocity(const t_param params, std::vector<my_float> &cells, std::vector<cl_char> &obstacles)
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
	  local_density += cells[kk*params.nx*params.ny + curr_cell];
	}
	/* x-component of velocity */
	u_x = (cells[1*params.nx*params.ny + curr_cell] + 
		    cells[5*params.nx*params.ny + curr_cell] + 
		    cells[8*params.nx*params.ny + curr_cell]
		    - (cells[3*params.nx*params.ny + curr_cell] + 
		       cells[6*params.nx*params.ny + curr_cell] + 
		       cells[7*params.nx*params.ny + curr_cell])) / 
	  local_density;
	/* compute y velocity component */
	u_y = (cells[2*params.nx*params.ny + curr_cell] + 
		    cells[5*params.nx*params.ny + curr_cell] + 
		    cells[6*params.nx*params.ny + curr_cell]
		    - (cells[4*params.nx*params.ny + curr_cell] + 
		       cells[7*params.nx*params.ny + curr_cell] + 
		       cells[8*params.nx*params.ny + curr_cell])) /
	  local_density;
	/* accumulate the norm of x- and y- velocity components */
	tot_u += my_sqrt((u_x * u_x) + (u_y * u_y));
	/* increase counter of inspected cells */
	++tot_cells;
    }
  }

  return tot_u / (my_float)tot_cells;
}

my_float calc_reynolds(const t_param params, std::vector<my_float> &cells, std::vector<cl_char> &obstacles)
{
  const my_float viscosity = 1.0 / 6.0 * (2.0 / params.omega - 1.0);
  
  return av_velocity(params,cells,obstacles) * params.reynolds_dim / viscosity;
}

my_float total_density(const t_param params, std::vector<my_float> &cells)
{
  int ii,jj,kk;        /* generic counters */
  my_float total = 0.0;  /* accumulator */

  for(ii=0;ii<params.ny;ii++) {
    for(jj=0;jj<params.nx;jj++) {
      for(kk=0;kk<NSPEEDS;kk++) {
	total += cells[kk*params.nx*params.ny + ii*params.nx + jj];
      }
    }
  }

  return total;
}

int write_values(const t_param params, std::vector<my_float> &cells, std::vector<cl_char> &obstacles, std::vector<my_float> &av_vels, const unsigned int nwork_groups)
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
      int curr_cell = ii * params.nx + jj;
      /* an occupied cell */
      if(obstacles[curr_cell]) {
	u_x = u_y = u = 0.0;
	pressure = params.density * c_sq;
      }
      /* no obstacle */
      else {
	local_density = 0.0;
	for(kk=0;kk<NSPEEDS;kk++) {
	  local_density += cells[kk*params.nx*params.ny + curr_cell];
	}
	/* x-component of velocity */
	u_x = (cells[1*params.nx*params.ny + curr_cell] + 
		    cells[5*params.nx*params.ny + curr_cell] + 
		    cells[8*params.nx*params.ny + curr_cell]
		    - (cells[3*params.nx*params.ny + curr_cell] + 
		       cells[6*params.nx*params.ny + curr_cell] + 
		       cells[7*params.nx*params.ny + curr_cell])) / 
	  local_density;
	/* compute y velocity component */
	u_y = (cells[2*params.nx*params.ny + curr_cell] + 
		    cells[5*params.nx*params.ny + curr_cell] + 
		    cells[6*params.nx*params.ny + curr_cell]
		    - (cells[4*params.nx*params.ny + curr_cell] + 
		       cells[7*params.nx*params.ny + curr_cell] + 
		       cells[8*params.nx*params.ny + curr_cell])) /
	  local_density;
	/* compute norm of velocity */
	u = my_sqrt((u_x * u_x) + (u_y * u_y));
	/* compute pressure */
	pressure = local_density * c_sq;
      }
      /* write to file */
      fprintf(fp,"%d %d %.12E %.12E %.12E %.12E %d\n",jj,ii,u_x,u_y,u,pressure,obstacles[curr_cell]);
    }
  }

  fclose(fp);

  fp = fopen(AVVELSFILE,"w");
  if (fp == NULL) {
    die("could not open file output file",__LINE__,__FILE__);
  }
  for (ii=0;ii<params.maxIters;ii++) {
    fprintf(fp,"%d:\t%.12E\n", ii, (double)av_vels.at(ii*nwork_groups));
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

//
// Use this function to create a context and device OpenCL handle on
// Blue Crystal Phase 3. Care has to be taken in order to use the
// GPU assigned by the cluster queue system. This function takes
// care of this for you.
//
void init_context_bcp3(cl::Context& context, cl::Device& device)
{
  //
  // Get the index into the device array allocated by the queue on BCP3
  //
  char* path = std::getenv("PBS_GPUFILE");
  if (path == NULL)
    {
      std::cerr << "Error: PBS_GPUFILE environment variable not set by queue\n";
      exit(-1);
    }
  std::ifstream gpufile(path);
  if (!gpufile.is_open())
    {
      std::cerr << "Error: PBS_GPUFILE not found\n";
      exit(-1);
    }

  std::string line;
  std::getline(gpufile, line);
  char c = line.at(line.size() - 1);
  int device_index = strtol(&c, NULL, 10);

  gpufile.close();

  cl_int err;

  // Query platforms
  std::vector<cl::Platform> platforms;
  err = cl::Platform::get(&platforms);
  if (err != CL_SUCCESS) {std::cerr << "Error getting platforms: "<< err << "\n"; exit(-1);}

  // Get devices for each platform - stop when found a GPU
  std::vector<cl::Device> devices;

  unsigned int i;
  for (i = 0; i < platforms.size(); i++)
    {
      err = platforms[i].getDevices(CL_DEVICE_TYPE_GPU, &devices);
      if (err == CL_SUCCESS && devices.size() > 0)
	break;
    }
  if (devices.size() == 0)
    {
      std::cerr << "Error: no GPUs found";
      exit(-1);
    }

  // Assign the device id
  device = devices[device_index];

  // Create the context
  std::vector<cl::Device> chosen_device;
  chosen_device.push_back(device);
  context = cl::Context(chosen_device, NULL, NULL, NULL, &err);
  if (err != CL_SUCCESS) {std::cerr << "Error creating context: " << err << "\n"; exit(-1);}
}

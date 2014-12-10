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
int initialise(const char* paramfile, const char* obstaclefile, t_param* params, std::vector<t_speed>** cells_ptr,
	       std::vector<t_speed>** tmp_cells_ptr, std::vector<int>** obstacles_ptr, unsigned int &obstacle_count,
	       std::vector<my_float> &av_vels, std::vector<t_adjacency>** adjacency);

/* 
** The main calculation methods.
** timestep calls, in order, the functions:
** accelerate_flow(), propagate(), rebound() & collision()
*/
int timestep(const t_param params, std::vector<t_speed> &cells, std::vector<t_speed> &tmp_cells, std::vector<int> &obstacles, const std::vector<t_adjacency> &adjacency);
//int accelerate_flow(const t_param params, std::vector<t_speed> &cells, std::vector<int> &obstacles);
//int propagate_prep(const t_param params, std::vector<t_adjacency> &adjacency);
//int propagate(const t_param params, std::vector<t_speed> &cells, std::vector<t_speed> &tmp_cells, const std::vector<t_adjacency> &adjacency);
//int collision(const t_param params, std::vector<t_speed> &cells, std::vector<t_speed> &tmp_cells, std::vector<int> &obstacles);
int write_values(const t_param params, std::vector<t_speed> &cells, std::vector<int> &obstacles, std::vector<my_float> &av_vels);

/* finalise, including freeing up allocated memory */
//TODO: Fix finalise
//int finalise(const t_param* params, t_speed** cells_ptr, t_speed** tmp_cells_ptr,
//	     int** obstacles_ptr, my_float** av_vels_ptr);

/* Sum all the densities in the grid.
** The total should remain constant from one timestep to the next. */
my_float total_density(const t_param params, std::vector<t_speed> &cells);

/* compute average velocity */
//my_float av_velocity(const t_param params, std::vector<t_speed> &cells, std::vector<int> &obstacles);

/* calculate Reynolds number */
my_float calc_reynolds(const t_param params, std::vector<t_speed> &cells, std::vector<int> &obstacles);

/* utility functions */
void die(const char* message, const int line, const char *file);
void usage(const char* exe);

/*
** main program:
** initialise, timestep loop, finalise
*/
int main(int argc, char* argv[])
{
  char*    paramfile = NULL;    /* name of the input parameter file */
  char*    obstaclefile = NULL; /* name of a the input obstacle file */
  t_param  params;              /* struct to hold parameter values */
  std::vector<t_speed>* cells     = NULL;    /* grid containing fluid densities */
  std::vector<t_speed>* tmp_cells = NULL;    /* scratch space */
  std::vector<int>*     obstacles = NULL;    /* grid indicating which cells are blocked */
  std::vector<my_float>  av_vels;    /* a record of the av. velocity computed for each timestep */
  std::vector<my_float>  partial_tot_u;
  int      ii;                  /* generic counter */
  struct timeval timstr;        /* structure to hold elapsed time */
  struct rusage ru;             /* structure to hold CPU time--system and user */
  double tic,toc;               /* floating point numbers to calculate elapsed wallclock time */
  double usrtim;                /* floating point number to record elapsed user CPU time */
  double systim;                /* floating point number to record elapsed system CPU time */
  std::vector<t_adjacency>* adjacency = NULL; /* store adjacency for each cell in each direction for propagate. */
  unsigned int obstacle_count = 0;

  /* parse the command line */
  if(argc != 3) {
    usage(argv[0]);
  }
  else{
    paramfile = argv[1];
    obstaclefile = argv[2];
  }
  
  //try {
    // OpenCL setup. From HandsOnOpenCL
    cl_uint deviceIndex = 0;
    parseArguments(argc, argv, &deviceIndex);
  
    std::vector<cl::Device> devices;
    unsigned numDevices = getDeviceList(devices);

    if (deviceIndex >= numDevices) {
      std::cout << "Invalid device index (try '--list')\n";
      return EXIT_FAILURE;
    }

    cl::Device device = devices[deviceIndex];
    //try{
    std::string name;
    getDeviceName(device, name);
    std::cout << "Using OpenCL device: " << name << "\n";

    std::vector<cl::Device> chosen_device;
    chosen_device.push_back(device);
    cl::Context context(chosen_device);
    cl::CommandQueue queue(context, device);

    /* initialise our data structures and load values from file */
    initialise(paramfile, obstaclefile, &params, &cells, &tmp_cells, &obstacles, obstacle_count, av_vels, &adjacency);

    av_vels.reserve(params.maxIters);

    // Read in and compile OpenCL kernels
    cl::Program pp_program(context, util::loadProgram("./propagate_prep.cl"), false);
    cl::Program cl_collision(context, util::loadProgram("./collision.cl"), false);
    cl::Program cl_propagate(context, util::loadProgram("./propagate.cl"), false);
    cl::Program cl_accelerate_flow(context, util::loadProgram("./accelerate_flow.cl"), false);
    cl::Program cl_av_velocity(context, util::loadProgram("./av_velocity.cl"), false);

    // Potential build flags:
    // "-cl-single-precision-constant -cl-denorms-are-zero -cl-strict-aliasing -cl-mad-enable -cl-no-signed-zeros -cl-fast-relaxed-math"
      try {

    std::cout << "Beginning kernel build..." << std::endl;

    pp_program.build();
    cl_collision.build();
    cl_propagate.build();
    cl_accelerate_flow.build();
    cl_av_velocity.build();
    
    std::cout << "Kernel build complete" << std::endl;

    // Set variables to divide work in reduction.
    ::size_t nwork_groups;
    ::size_t work_group_size = 8; //max_size ???
    const ::size_t unit_length = 2; // TODO: How does this value effect performance/correctness?
    // Get kernel object to query information
    cl::Kernel ko_av_velocity(cl_av_velocity, "av_velocity");
    work_group_size = ko_av_velocity.getWorkGroupInfo<CL_KERNEL_WORK_GROUP_SIZE>(device);
    // From the work_group_size (the number of workers per group), problem size, and a constant work unit size
    // we can calculate the number of work groups needed.
    nwork_groups = (params.ny*params.nx) / (work_group_size*unit_length);


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
      work_group_size = (params.ny*params.nx) / (nwork_groups*unit_length); // Reset the work group size to fit the new group count.
    }

    printf(
	   " %d work groups of size %d.  %ld Integration steps\n",
	   (int)nwork_groups,
	   (int)work_group_size,
	   work_group_size*unit_length*nwork_groups);

    cl::make_kernel<cl::Buffer> propagate_prep(pp_program, "propagate_prep");
    cl::make_kernel<my_float, cl::Buffer, cl::Buffer, cl::Buffer> collision(cl_collision, "collision");
    cl::make_kernel<cl::Buffer, cl::Buffer, cl::Buffer> propagate(cl_propagate, "propagate");
    cl::make_kernel<t_param, cl::Buffer, cl::Buffer> accelerate_flow(cl_accelerate_flow, "accelerate_flow");
    cl::make_kernel<int, cl::Buffer, cl::Buffer, cl::LocalSpaceArg, cl::Buffer> av_velocity(cl_av_velocity, "av_velocity");

    // Create OpenCL buffer TODO: Don't bother with this copy operation and keep fully on device... or copy to constant memory?
    //cl::Buffer cl_adjacency = cl::Buffer(context, adjacency->begin(), adjacency->end(), false);
    cl::Buffer cl_adjacency = cl::Buffer(context, CL_MEM_WRITE_ONLY, sizeof(t_adjacency) * params.nx * params.ny);
    cl::Buffer cl_cells = cl::Buffer(context, cells->begin(), cells->end(), false);
    cl::Buffer cl_tmp_cells = cl::Buffer(context, tmp_cells->begin(), tmp_cells->end(), false);
    cl::Buffer cl_obstacles = cl::Buffer(context, obstacles->begin(), obstacles->end(), true);
    cl::Buffer cl_round_tot_u = cl::Buffer(context, CL_MEM_WRITE_ONLY, sizeof(float) * nwork_groups); // Buffer to hold partial sums for reduction.

    // Vector on host so we can sum the partial sums ourselves.
    partial_tot_u.resize(nwork_groups);

    propagate_prep(cl::EnqueueArgs(queue, cl::NDRange(params.ny, params.nx)), cl_adjacency);

    // End OpenCL operations
    queue.finish();

    std::cout << "Trundling into the timestep loop." << std::endl;

  /* iterate for maxIters timesteps */
  gettimeofday(&timstr,NULL);
  tic=timstr.tv_sec+(timstr.tv_usec/1000000.0);

  // Can we do this outside the timing? Probably not!
  //propagate_prep(params, *adjacency);

  // Copy into buffers. TODO: NO COPIES, BAD.
  //cl::copy(queue, cells->begin(), cells->end(), cl_cells);
  //cl::copy(queue, tmp_cells->begin(), tmp_cells->end(), cl_tmp_cells);

  for (ii=0;ii<params.maxIters;ii++) {
    //timestep(params,*cells,*tmp_cells,*obstacles,*adjacency); //TODO: Make me nice again?
    accelerate_flow(cl::EnqueueArgs(queue, cl::NDRange(params.nx)), params, cl_cells, cl_obstacles);
    propagate(cl::EnqueueArgs(queue, cl::NDRange(params.ny*params.nx)), cl_cells, cl_tmp_cells, cl_adjacency);
    collision(cl::EnqueueArgs(queue, cl::NDRange(params.ny*params.nx)), params.omega, cl_cells, cl_tmp_cells, cl_obstacles);
    av_velocity(cl::EnqueueArgs(queue, cl::NDRange(params.nx*params.ny/unit_length), cl::NDRange(work_group_size)), unit_length, cl_cells, cl_obstacles, cl::Local(sizeof(float) * work_group_size), cl_round_tot_u);

    queue.finish();

    // Copy the partial sums off the device
    cl::copy(queue, cl_round_tot_u, partial_tot_u.begin(), partial_tot_u.end());

    // Do the final summation on the host
    float tot_u = 0.0;
    for (unsigned int i = 0; i < nwork_groups; i++) {
      tot_u += partial_tot_u.at(i);
    }
    av_vels[ii] = tot_u / ((params.ny*params.nx) - obstacle_count);

#ifdef DEBUG
    printf("==timestep: %d==\n",ii);
    printf("av velocity: %.12E\n", av_vels[ii]);
    printf("tot density: %.12E\n",total_density(params,*cells));
#endif
  }

  std::cout << "out of simulation" << std::endl;
  
  // Block on finish then copy back.
  queue.finish();
  cl::copy(queue, cl_cells, cells->begin(), cells->end());
  //cl::copy(queue, cl_tot_u, tot_u.begin(), tot_u.end());
  //cl::copy(queue, cl_tot_cells, tot_cells.begin(), tot_cells.end());

  // for (ii=0;ii<params.maxIters;ii++) {
  //   av_vels[ii] = tot_u[ii] / (float)tot_cells[ii];
  // }

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
  write_values(params,*cells,*obstacles,av_vels);
  //  finalise(&params, &cells, &tmp_cells, &obstacles, &av_vels);
  

  } catch (cl::Error &err) {
    std::cout << "Exception\n";
    std::cerr << err.what() << "(" << err_code(err.err()) << std::endl; 
    std::string blog = cl_av_velocity.getBuildInfo<CL_PROGRAM_BUILD_LOG>(device);
    std::cerr << blog << std::endl;
  }

  return EXIT_SUCCESS;
}

// int timestep(const t_param params, std::vector<t_speed> &cells, std::vector<t_speed> &tmp_cells, std::vector<int> &obstacles, const std::vector<t_adjacency> &adjacency)
// {
//   accelerate_flow(params,cells,obstacles);
//   propagate(params,cells,tmp_cells,adjacency);
//   collision(params,cells,tmp_cells,obstacles);
//   return EXIT_SUCCESS; 
// }

// int accelerate_flow(const t_param params, std::vector<t_speed> &cells, std::vector<int> &obstacles)
// {
//   int ii,jj;     /* generic counters */
//   my_float w1,w2;  /* weighting factors */
  
//   /* compute weighting factors */
//   w1 = params.density * params.accel / 9.0;
//   w2 = params.density * params.accel / 36.0;

//   /* modify the 2nd row of the grid */
//   ii=params.ny - 2;
//   for(jj=0;jj<params.nx;jj++) {
//     /* if the cell is not occupied and
//     ** we don't send a density negative */
//     if( !obstacles[ii*params.nx + jj] && 
// 	(cells[ii*params.nx + jj].speeds[3] - w1) > 0.0 &&
// 	(cells[ii*params.nx + jj].speeds[6] - w2) > 0.0 &&
// 	(cells[ii*params.nx + jj].speeds[7] - w2) > 0.0 ) {
//       /* increase 'east-side' densities */
//       cells[ii*params.nx + jj].speeds[1] += w1;
//       cells[ii*params.nx + jj].speeds[5] += w2;
//       cells[ii*params.nx + jj].speeds[8] += w2;
//       /* decrease 'west-side' densities */
//       cells[ii*params.nx + jj].speeds[3] -= w1;
//       cells[ii*params.nx + jj].speeds[6] -= w2;
//       cells[ii*params.nx + jj].speeds[7] -= w2;
//     }
//   }

//   return EXIT_SUCCESS;
// }

// int propagate_prep(const t_param params, std::vector<t_adjacency> &adjacency)
// {
//   int ii,jj;            /* generic counters */
//   int x_e,x_w,y_n,y_s;  /* indices of neighbouring cells */

//   /* loop over _all_ cells */
//   for(ii=0;ii<params.ny;ii++) {
//     for(jj=0;jj<params.nx;jj++) {
//       /* determine indices of axis-direction neighbours
//       ** respecting periodic boundary conditions (wrap around) */
//       y_n = (ii + 1) % params.ny;
//       x_e = (jj + 1) % params.nx;
//       y_s = (ii == 0) ? (ii + params.ny - 1) : (ii - 1);
//       x_w = (jj == 0) ? (jj + params.nx - 1) : (jj - 1);
//       //Pre-calculate the adjacent cells to propagate to.
//       //adjacency[ii*params.nx + jj].index[0] = ii * params.nx + jj; // Centre, ignore
//       adjacency[ii*params.nx + jj].index[1] = ii * params.nx + x_e; // N
//       adjacency[ii*params.nx + jj].index[2] = y_n * params.nx + jj; // E
//       adjacency[ii*params.nx + jj].index[3] = ii * params.nx + x_w; // W
//       adjacency[ii*params.nx + jj].index[4] = y_s * params.nx + jj; // S
//       adjacency[ii*params.nx + jj].index[5] = y_n * params.nx + x_e; // NE
//       adjacency[ii*params.nx + jj].index[6] = y_n * params.nx + x_w; // NW
//       adjacency[ii*params.nx + jj].index[7] = y_s * params.nx + x_w; // SW
//       adjacency[ii*params.nx + jj].index[8] = y_s * params.nx + x_e; // SE
//     }
//   }

//   return EXIT_SUCCESS;
// }

// int propagate(const t_param params, std::vector<t_speed> &cells, std::vector<t_speed> &tmp_cells, const std::vector<t_adjacency> &adjacency)
// {
//   int curr_cell; // Stop re-calculating the array index repeatedly.
//   const int cell_lim = (params.ny * params.nx);

//   /* loop over _all_ cells */
//   for(curr_cell=0;curr_cell<cell_lim;++curr_cell) {
//     /* propagate densities to neighbouring cells, following
//     ** appropriate directions of travel and writing into
//     ** scratch space grid */
//     tmp_cells[curr_cell].speeds[0] = cells[curr_cell].speeds[0];                     /* central cell, */
//                                                                                      /* no movement */
//     tmp_cells[adjacency[curr_cell].index[1]].speeds[1] = cells[curr_cell].speeds[1]; /* east */
//     tmp_cells[adjacency[curr_cell].index[2]].speeds[2] = cells[curr_cell].speeds[2]; /* north */
//     tmp_cells[adjacency[curr_cell].index[3]].speeds[3] = cells[curr_cell].speeds[3]; /* west */
//     tmp_cells[adjacency[curr_cell].index[4]].speeds[4] = cells[curr_cell].speeds[4]; /* south */
//     tmp_cells[adjacency[curr_cell].index[5]].speeds[5] = cells[curr_cell].speeds[5]; /* north-east */
//     tmp_cells[adjacency[curr_cell].index[6]].speeds[6] = cells[curr_cell].speeds[6]; /* north-west */
//     tmp_cells[adjacency[curr_cell].index[7]].speeds[7] = cells[curr_cell].speeds[7]; /* south-west */
//     tmp_cells[adjacency[curr_cell].index[8]].speeds[8] = cells[curr_cell].speeds[8]; /* south-east */
//   }

//   return EXIT_SUCCESS;
// }

// int collision(const t_param params, std::vector<t_speed> &cells, std::vector<t_speed> &tmp_cells, std::vector<int> &obstacles)
// {
//   int kk;                         /* generic counters */
//   const my_float c_sq = 1.0/3.0;  /* square of speed of sound */
//   const my_float w0 = 4.0/9.0;    /* weighting factor */
//   const my_float w1 = 1.0/9.0;    /* weighting factor */
//   const my_float w2 = 1.0/36.0;   /* weighting factor */
//   my_float u_x,u_y;               /* av. velocities in x and y directions */
//   my_float u[NSPEEDS];            /* directional velocities */
//   my_float d_equ[NSPEEDS];        /* equilibrium densities */
//   my_float u_sq;                  /* squared velocity */
//   my_float local_density;         /* sum of densities in a particular cell */

//   int curr_cell; // Stop re-calculating the array index repeatedly.
//   const int cell_lim = (params.ny * params.nx);

//   /* loop over the cells in the grid
//   ** NB the collision step is called after
//   ** the propagate step and so values of interest
//   ** are in the scratch-space grid */
//   for(curr_cell=0;curr_cell<cell_lim;++curr_cell) {
//       if(obstacles[curr_cell]) {
// 	/* called after propagate, so taking values from scratch space
// 	** mirroring, and writing into main grid */
// 	cells[curr_cell].speeds[1] = tmp_cells[curr_cell].speeds[3];
// 	cells[curr_cell].speeds[2] = tmp_cells[curr_cell].speeds[4];
// 	cells[curr_cell].speeds[3] = tmp_cells[curr_cell].speeds[1];
// 	cells[curr_cell].speeds[4] = tmp_cells[curr_cell].speeds[2];
// 	cells[curr_cell].speeds[5] = tmp_cells[curr_cell].speeds[7];
// 	cells[curr_cell].speeds[6] = tmp_cells[curr_cell].speeds[8];
// 	cells[curr_cell].speeds[7] = tmp_cells[curr_cell].speeds[5];
// 	cells[curr_cell].speeds[8] = tmp_cells[curr_cell].speeds[6];
//       } else {
// 	/* don't consider occupied cells */
// 	/* compute local density total */
// 	local_density = 0.0;
// 	for(kk=0;kk<NSPEEDS;kk++) {
// 	  local_density += tmp_cells[curr_cell].speeds[kk];
// 	}

// 	/* compute x velocity component */
// 	u_x = (tmp_cells[curr_cell].speeds[1] + 
// 	       tmp_cells[curr_cell].speeds[5] + 
// 	       tmp_cells[curr_cell].speeds[8]
// 	       - (tmp_cells[curr_cell].speeds[3] + 
// 		  tmp_cells[curr_cell].speeds[6] + 
// 		  tmp_cells[curr_cell].speeds[7]))
// 	  / local_density;

// 	/* compute y velocity component */
// 	u_y = (tmp_cells[curr_cell].speeds[2] + 
// 	       tmp_cells[curr_cell].speeds[5] + 
// 	       tmp_cells[curr_cell].speeds[6]
// 	       - (tmp_cells[curr_cell].speeds[4] + 
// 		  tmp_cells[curr_cell].speeds[7] + 
// 		  tmp_cells[curr_cell].speeds[8]))
// 	  / local_density;

// 	/* velocity squared */ 
// 	u_sq = u_x * u_x + u_y * u_y;
// 	/* directional velocity components */
// 	u[1] =   u_x;        /* east */
// 	u[2] =         u_y;  /* north */
// 	u[3] = - u_x;        /* west */
// 	u[4] =       - u_y;  /* south */
// 	u[5] =   u_x + u_y;  /* north-east */
// 	u[6] = - u_x + u_y;  /* north-west */
// 	u[7] = - u_x - u_y;  /* south-west */
// 	u[8] =   u_x - u_y;  /* south-east */
// 	/* equilibrium densities */
// 	/* zero velocity density: weight w0 */
// 	d_equ[0] = w0 * local_density * (1.0 - u_sq / (2.0 * c_sq));
// 	/* axis speeds: weight w1 */
// 	d_equ[1] = w1 * local_density * (1.0 + u[1] / c_sq
// 					 + (u[1] * u[1]) / (2.0 * c_sq * c_sq)
// 					 - u_sq / (2.0 * c_sq));
// 	d_equ[2] = w1 * local_density * (1.0 + u[2] / c_sq
// 					 + (u[2] * u[2]) / (2.0 * c_sq * c_sq)
// 					 - u_sq / (2.0 * c_sq));
// 	d_equ[3] = w1 * local_density * (1.0 + u[3] / c_sq
// 					 + (u[3] * u[3]) / (2.0 * c_sq * c_sq)
// 					 - u_sq / (2.0 * c_sq));
// 	d_equ[4] = w1 * local_density * (1.0 + u[4] / c_sq
// 					 + (u[4] * u[4]) / (2.0 * c_sq * c_sq)
// 					 - u_sq / (2.0 * c_sq));
// 	/* diagonal speeds: weight w2 */
// 	d_equ[5] = w2 * local_density * (1.0 + u[5] / c_sq
// 					 + (u[5] * u[5]) / (2.0 * c_sq * c_sq)
// 					 - u_sq / (2.0 * c_sq));
// 	d_equ[6] = w2 * local_density * (1.0 + u[6] / c_sq
// 					 + (u[6] * u[6]) / (2.0 * c_sq * c_sq)
// 					 - u_sq / (2.0 * c_sq));
// 	d_equ[7] = w2 * local_density * (1.0 + u[7] / c_sq
// 					 + (u[7] * u[7]) / (2.0 * c_sq * c_sq)
// 					 - u_sq / (2.0 * c_sq));
// 	d_equ[8] = w2 * local_density * (1.0 + u[8] / c_sq
// 					 + (u[8] * u[8]) / (2.0 * c_sq * c_sq)
// 					 - u_sq / (2.0 * c_sq));
// 	/* relaxation step */
// 	for(kk=0;kk<NSPEEDS;kk++) {
// 	  cells[curr_cell].speeds[kk] = (tmp_cells[curr_cell].speeds[kk]
// 						 + params.omega * 
// 						 (d_equ[kk] - tmp_cells[curr_cell].speeds[kk]));
// 	}
//     }
//   }

//   return EXIT_SUCCESS; 
//}

int initialise(const char* paramfile, const char* obstaclefile,
	       t_param* params, std::vector<t_speed>** cells_ptr, std::vector<t_speed>** tmp_cells_ptr, 
	       std::vector<int>** obstacles_ptr, unsigned int &obstacle_count, std::vector<my_float> &av_vels, std::vector<t_adjacency>** adjacency)
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
  // *cells_ptr = (t_speed*)malloc(sizeof(t_speed)*(params->ny*params->nx));
  // if (*cells_ptr == NULL) 
  //   die("cannot allocate memory for cells",__LINE__,__FILE__);
  *cells_ptr = new std::vector<t_speed>(params->ny*params->nx);

  /* 'helper' grid, used as scratch space */
  // *tmp_cells_ptr = (t_speed*)malloc(sizeof(t_speed)*(params->ny*params->nx));
  // if (*tmp_cells_ptr == NULL) 
  //   die("cannot allocate memory for tmp_cells",__LINE__,__FILE__);
  *tmp_cells_ptr = new std::vector<t_speed>(params->ny*params->nx);
  
  /* the map of obstacles */
  // *obstacles_ptr = (int*)malloc(sizeof(int*)*(params->ny*params->nx));
  // if (*obstacles_ptr == NULL) 
  //   die("cannot allocate column memory for obstacles",__LINE__,__FILE__);
  *obstacles_ptr = new std::vector<int>(params->ny*params->nx);

  /* adjacency for propagate */
  // *adjacency = (t_adjacency*)malloc(sizeof(t_adjacency) * (params->ny*params->nx));
  // if (*adjacency == NULL)
  //   die("cannot allocate adjacency memory",__LINE__,__FILE__);
  *adjacency = new std::vector<t_adjacency>(params->ny*params->nx);

  /* initialise densities */
  w0 = params->density * 4.0/9.0;
  w1 = params->density      /9.0;
  w2 = params->density      /36.0;

  for(ii=0;ii<params->ny;ii++) {
    for(jj=0;jj<params->nx;jj++) {
      /* centre */
      (**cells_ptr)[ii*params->nx + jj].speeds[0] = w0;
      /* axis directions */
      (**cells_ptr)[ii*params->nx + jj].speeds[1] = w1;
      (**cells_ptr)[ii*params->nx + jj].speeds[2] = w1;
      (**cells_ptr)[ii*params->nx + jj].speeds[3] = w1;
      (**cells_ptr)[ii*params->nx + jj].speeds[4] = w1;
      /* diagonals */
      (**cells_ptr)[ii*params->nx + jj].speeds[5] = w2;
      (**cells_ptr)[ii*params->nx + jj].speeds[6] = w2;
      (**cells_ptr)[ii*params->nx + jj].speeds[7] = w2;
      (**cells_ptr)[ii*params->nx + jj].speeds[8] = w2;
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

  /* 
  ** allocate space to hold a record of the avarage velocities computed 
  ** at each timestep
  */
  av_vels.reserve(params->maxIters);

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

my_float av_velocity(const t_param params, std::vector<t_speed> &cells, std::vector<int> &obstacles)
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

  return tot_u / (my_float)tot_cells;
}

my_float calc_reynolds(const t_param params, std::vector<t_speed> &cells, std::vector<int> &obstacles)
{
  const my_float viscosity = 1.0 / 6.0 * (2.0 / params.omega - 1.0);
  
  return av_velocity(params,cells,obstacles) * params.reynolds_dim / viscosity;
}

my_float total_density(const t_param params, std::vector<t_speed> &cells)
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

int write_values(const t_param params, std::vector<t_speed> &cells, std::vector<int> &obstacles, std::vector<my_float> &av_vels)
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
  exit(EXIT_FAILURE);
}

void usage(const char* exe)
{
  fprintf(stderr, "Usage: %s <paramfile> <obstaclefile>\n", exe);
  exit(EXIT_FAILURE);
}

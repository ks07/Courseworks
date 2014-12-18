__kernel void final_reduce(const unsigned int nwork_groups, const unsigned int cell_cnt, __global float* round_tot_u, const unsigned int lim) {
  const unsigned int iter = get_global_id(0);
  float tot_u = 0.0;

  if (iter < lim) {
    for (unsigned int i = 0; i < nwork_groups; i++) {
      tot_u += round_tot_u[iter * nwork_groups + i];
    }
    round_tot_u[iter * nwork_groups] = tot_u / cell_cnt;
  }
}

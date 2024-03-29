#!/usr/bin/env python2
from __future__ import print_function
from montmul import mont_mul, get_mp, get_mont_rep
import sys, subprocess, math, random

def get_params(paramfile):
  infile = open(paramfile, 'r')

  N_raw = infile.readline().strip()
  N = int(N_raw, 16)
  e_raw = infile.readline().strip()
  e = int(e_raw, 16)

  return (N, e, N_raw, e_raw)

def interact(c):
  global queries
  queries = queries + 1

  # Send ciphertext c to attack target as hex string
  target_in.write( "{0:x}\n".format(c) )
  target_in.flush()

  # Receive time from attack target.
  delta = int( target_out.readline().strip() )
  m_raw = target_out.readline().strip()
  m = int(m_raw, 16)

  return {'time':delta, 'm':m, 'm_raw':m_raw}

def attack():
  N = params[0]
  some_c = [random.randrange(N) for _ in range(10000)]
  found_d = 1

  # Get some mont params
  mont_params = get_mp(N)

  # time and decrypt
  mont_m_list  = []
  times        = []
  mont_tmps    = []
  mont_tmps_k0 = []
  mont_tmps_k1 = []

  mont_tmp_start = get_mont_rep(1, mont_params)

  for c in some_c:
    from_target = interact(c)
    times.append(from_target['time'])
    mont_m = get_mont_rep(c, mont_params)
    mont_m_list.append(mont_m)
    mont_tmp = mont_tmp_start

    # Do first round where we know the bit is 1
    tmp_k0, _ = mont_mul(mont_tmp, mont_tmp, mont_params)
    tmp_k1, _ = mont_mul(tmp_k0, mont_m, mont_params)
    mont_tmps_k0.append(tmp_k0)
    mont_tmps_k1.append(tmp_k1)

    # We know we want k1. Need to square out here cause we already do it
    mont_tmps.append(mont_mul(tmp_k1, tmp_k1, mont_params)[0])

  # The max key size is going to be the bit length of N, but will almost certainly be much smaller
  # We can determine when we have reached the final bit by the significance of the difference values.
  # From our target, sensible avg difference values range from ~16 to ~8 cycles
  # Thus lets presume that when we hit a difference of < 4 we should presume we have got to the last bit
  N_bits = mont_params['N_size'] * 64
  final_cutoff = 4.0

  for key_index in xrange(1, N_bits):
    f_sum = [0.0, 0.0, 0.0, 0.0]
    f_cnt = [ 0,   0,   0,   0 ]

    for challenge_index, tmp in enumerate(mont_tmps):      
      # Presume k = 1
      tmp_k1, _ = mont_mul(tmp, mont_m_list[challenge_index], mont_params)
      tmp_k1, red1 = mont_mul(tmp_k1, tmp_k1, mont_params)
      mont_tmps_k1[challenge_index] = tmp_k1

      # Presume k = 0
      tmp_k0, red2 = mont_mul(tmp, tmp, mont_params)
      mont_tmps_k0[challenge_index] = tmp_k0

      # Add to F1 (0) if red1, else F2 (1)
      if red1:
        f_sum[0] = f_sum[0] + times[challenge_index]
        f_cnt[0] = f_cnt[0] + 1
      else:
        f_sum[1] = f_sum[1] + times[challenge_index]
        f_cnt[1] = f_cnt[1] + 1

      # Add to F3 or F4
      if red2:
        f_sum[2] = f_sum[2] + times[challenge_index]
        f_cnt[2] = f_cnt[2] + 1
      else:
        f_sum[3] = f_sum[3] + times[challenge_index]
        f_cnt[3] = f_cnt[3] + 1

    f_avg = [0.0, 0.0, 0.0, 0.0]
    for i in range(0, 4):
      f_avg[i] = f_sum[i] / f_cnt[i]

    diff_f1_f2 = f_avg[0] - f_avg[1]
    diff_f3_f4 = f_avg[2] - f_avg[3]

    found_d = found_d << 1

    if diff_f1_f2 < final_cutoff and diff_f3_f4 < final_cutoff:
      print("Guessing target key size of {0} bits".format(key_index + 1))
      # Return our current value, we must test both values of bit i
      return (found_d | 1)
    elif diff_f1_f2 > diff_f3_f4:
      # Guess k is hot
      found_d = found_d | 1
      # Keep k1 list
      mont_tmps = mont_tmps_k1
    else:
      # Guess k low
      mont_tmps = mont_tmps_k0

    print("Found bit", key_index, bin(found_d))

  return found_d

def verify_d(d_guess):
  m = random.randrange(params[0])
  c = pow(m, params[1], params[0])
  m_ = pow(c, d_guess, params[0])
  return m == m_

if ( __name__ == "__main__" ) :
  if (len(sys.argv) != 3) :
    print("Usage: attack.py <target executable> <parameter file>")
    sys.exit(1)

  # Read param file
  params = get_params(sys.argv[2])

  # Produce a sub-process representing the attack target.
  target = subprocess.Popen( args   = sys.argv[ 1 ],
                             stdout = subprocess.PIPE,
                             stdin  = subprocess.PIPE )

  # Construct handles to attack target standard input and output.
  target_out = target.stdout
  target_in  = target.stdin

  # Set a global counter of interactions
  queries = 0

  # Execute a function representing the attacker.
  guess_d = attack()

  # Check our guess
  if not verify_d(guess_d):
    guess_d = guess_d ^ 1
    assert(verify_d)

  print("Recovered private key d:\n{0:x}".format(guess_d))

  print("Total target interactions:", queries)

  # Terminate the target process
  target.terminate()

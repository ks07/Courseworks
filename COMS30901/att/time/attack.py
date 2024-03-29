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
  msg   = int( target_out.readline().strip(), 16 )

  return { 'time': delta, 'm': msg }

def add_challenges(count, c_list, time_list, mont_c_list, mont_tmp_list, d, mont_params):
  assert(len(time_list) == len(c_list) and len(c_list) == len(mont_c_list))

  # It is absolutely crucial we perform this step in the right place with the right list of tmps.
  # Failure to do so will ruin the attack!
  assert check_cpow(c_list[0], d, mont_tmp_list[0], mont_params)

  N = mont_params['N']
  for i in xrange(count):
    c = random.randrange(N)
#    c = c_list[0]
    from_target = interact(c)

    # Fill the base lists
    c_list.append(c)
    time_list.append(from_target['time'])
    mont_c_list.append(get_mont_rep(c, mont_params))

    # We need to bring these values up to speed with the rest of the algo
    c_pow_d = pow(c, d, N)
    mont_tmp_list.append(get_mont_rep(c_pow_d, mont_params))

#    assert(mont_tmp_list[-1] == mont_tmp_list[0])

def check_cpow(c, d, c_, mp):
  c_pow_d = pow(c, d, mp['N'])
  cm = get_mont_rep(c_pow_d, mp)
  # if cm == c_:
  #   print("MATCH!")
  # else:
  #   print("NOPE...")
  return cm == c_

def update_averages(time, red1, red2, f_sum, f_cnt):
  # Add to F1 (0) if red1, else F2 (1)
  t = 0 if red1 else 1
  f_sum[t] += time
  f_cnt[t] += 1
  
  # Add to F3 or F4
  t = 2 if red2 else 3
  f_sum[t] += time
  f_cnt[t] += 1

def calculate_options(tmp, mont_m, mont_params):
  # Presume k = 1
  tmp_k1, _ = mont_mul(tmp, mont_m, mont_params)
  tmp_k1, red1 = mont_mul(tmp_k1, tmp_k1, mont_params)

  # Presume k = 0
  tmp_k0, red2 = mont_mul(tmp, tmp, mont_params)

  return (tmp_k0, tmp_k1)
  
def attack():
  N = params[0]
  some_c = [random.randrange(N) for _ in range(4000)]
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

  # Keep note of our failure stage
  fail_stage_cnt = 0

  # Print the first bit, for completeness' sake
  print("Found bit 1", bin(found_d))

  key_index = 1
  while key_index < N_bits:
    assert key_index >= 1

    f_sum = [0.0, 0.0, 0.0, 0.0]
    f_cnt = [ 0,   0,   0,   0 ]

    # Make the key 1 bit longer
    found_d = found_d << 1

    assert len(bin(found_d)) - 2 == key_index + 1

    for challenge_index, tmp in enumerate(mont_tmps):
      # Presume k = 1
      tmp_k1, _ = mont_mul(tmp, mont_m_list[challenge_index], mont_params)
      tmp_k1, red1 = mont_mul(tmp_k1, tmp_k1, mont_params)
      mont_tmps_k1[challenge_index] = tmp_k1

      # Presume k = 0
      tmp_k0, red2 = mont_mul(tmp, tmp, mont_params)
      mont_tmps_k0[challenge_index] = tmp_k0

      update_averages(times[challenge_index], red1, red2, f_sum, f_cnt)

    f_avg = [0.0, 0.0, 0.0, 0.0]
    for i in range(0, 4):
      f_avg[i] = f_sum[i] / f_cnt[i]

    diff_f1_f2 = f_avg[0] - f_avg[1]
    diff_f3_f4 = f_avg[2] - f_avg[3]

    #print(diff_f1_f2, diff_f3_f4)
  
    if diff_f1_f2 < final_cutoff and diff_f3_f4 < final_cutoff:
      # We haven't seen a significant difference. Check the fail_stage_cnt:
      # 0 = First difficulty, check if we are done, add samples if not
      # 1 = Stuck, go back and flip bit

      # if we are at the first bit, we cannot backtrack so just grow regardless.
      if fail_stage_cnt == 0 or key_index == 1:
        print("Guessing target key size of {0} bits".format(key_index + 1))

        if verify_d(found_d):
          return found_d
        else:
          found_d = found_d ^ 1
          if verify_d(found_d):
            return found_d
          else:
            print('Not done... Adding more samples.')
            # Blank the lowest bit so challenges added are correct
            found_d = found_d >> 1
            found_d = found_d << 1
            add_challenges(2000, some_c, times, mont_m_list, mont_tmps, found_d, mont_params)
            print('New size:', len(some_c))
            # Need to expand the temp lists...
            mont_tmps_k0.extend([None]*(len(some_c)-len(mont_tmps_k0)))
            mont_tmps_k1.extend([None]*(len(some_c)-len(mont_tmps_k1)))
            # Retry this bit, i.e. don't increment key_index, shift back
            key_index = key_index
            found_d = found_d >> 1
            fail_stage_cnt = 1
      elif fail_stage_cnt == 1:
        print('Not done... Backtracking to bit:', key_index - 1, 'Erroneous d:', bin(found_d))
        # Just go back a bit. Our larger sample size should be enough to determine now (hopefully).
        key_index -= 1
        found_d = found_d >> 2
        # We need to update the mont_tmps for this new value.
        for ind, c in enumerate(some_c):
          c_pow_d = pow(c, found_d << 1, mont_params['N'])
          mont_tmps[ind] = get_mont_rep(c_pow_d, mont_params)
    elif diff_f1_f2 > diff_f3_f4:
      # Guess k is hot
      found_d = found_d | 1
      print("Found bit", key_index + 1, bin(found_d))
      # Keep k1 list
      mont_tmps = list(mont_tmps_k1)
      # Reset fail state
      fail_stage_cnt = 0
      key_index += 1
    else:
      # Guess k low
      print("Found bit", key_index + 1, bin(found_d))
      mont_tmps = list(mont_tmps_k0)
      # Reset fail state
      fail_stage_cnt = 0
      key_index += 1

  ## end while

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
    assert(verify_d(guess_d))

  print("Recovered private key d:\n{0:x}".format(guess_d))

  print("Total target interactions:", queries)

  # Terminate the target process
  target.terminate()

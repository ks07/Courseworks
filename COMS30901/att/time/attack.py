#!/usr/bin/env python2
from __future__ import print_function
from montmul import mont_mul, get_mp, get_mont_rep, undo_mont_rep
import sys, subprocess, math, random

def get_params(paramfile) :
  infile = open(paramfile, 'r')

  N_raw = infile.readline().strip()
  N = int(N_raw, 16)
  e_raw = infile.readline().strip()
  e = int(e_raw, 16)

  return (N, e, N_raw, e_raw)

def interact(c) :
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
  orig_m_list = []
  mont_m_list = []
  times       = []
  mont_tmps   = []

  for c in some_c:
    from_target = interact(c)
    orig_m_list.append(c)
    times.append(from_target['time'])
    mont_m_list.append(get_mont_rep(c, mont_params))
    mont_tmps.append(get_mont_rep(1, mont_params))

  # All the lists. We've given up harder than Lindsay Lohan
  mont_tmps_k0 = []
  mont_tmps_k1 = []

  # Do first round where we know the bit is 1
  for challenge_index, tmp in enumerate(mont_tmps):
    tmp_k0, _ = mont_mul(tmp, tmp, mont_params)
    tmp_k1, _ = mont_mul(tmp_k0, mont_m_list[challenge_index], mont_params)
    mont_tmps_k0.append(tmp_k0)
    mont_tmps_k1.append(tmp_k1)

  # We know we want k1. Need to square out here cause we already do it
  mont_tmps = map(lambda tmp_k1: mont_mul(tmp_k1, tmp_k1, mont_params)[0], mont_tmps_k1)

  # God knows when this bloody loop ends
  for key_index in range(1, 64):
    f_sum = ["lol",0.0,0.0,0.0,0.0]
    f_cnt = ["lol",0,0,0,0]

    for challenge_index, tmp in enumerate(mont_tmps):      
      # Presume k = 1
      tmp_k1, _ = mont_mul(tmp, mont_m_list[challenge_index], mont_params)
      tmp_k1, red1 = mont_mul(tmp_k1, tmp_k1, mont_params)
      mont_tmps_k1[challenge_index] = tmp_k1

      # Presume k = 0
      tmp_k0, red2 = mont_mul(tmp, tmp, mont_params)
      mont_tmps_k0[challenge_index] = tmp_k0

      # Add to F1 if red1, else F2
      if red1:
        f_sum[1] = f_sum[1] + times[challenge_index]
        f_cnt[1] = f_cnt[1] + 1
      else:
        f_sum[2] = f_sum[2] + times[challenge_index]
        f_cnt[2] = f_cnt[2] + 1

      # Add to F3 or F4
      if red2:
        f_sum[3] = f_sum[3] + times[challenge_index]
        f_cnt[3] = f_cnt[3] + 1
      else:
        f_sum[4] = f_sum[4] + times[challenge_index]
        f_cnt[4] = f_cnt[4] + 1

    f_avg = ["wut",0.0,0.0,0.0,0.0]
    for i in range(1,5):
      f_avg[i] = f_sum[i] / f_cnt[i]

    print(f_avg)

    diff_f1_f2 = f_avg[1] - f_avg[2]
    diff_f3_f4 = f_avg[3] - f_avg[4]

    found_d = found_d << 1

    if diff_f1_f2 > diff_f3_f4:
      # Guess k is hot
      found_d = found_d | 1
      # Keep k1 list
      mont_tmps = list(mont_tmps_k1)
    else:
      # Guess k low
      mont_tmps = list(mont_tmps_k0)
      
    print(bin(found_d))
  return found_d

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
  assert(verify_d(guess_d))

  print("Recovered private key d:\n{0:x}".format(guess_d))

  print("Total target interactions:", queries)

  # Terminate the target process
  target.terminate()

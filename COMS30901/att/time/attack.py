#!/usr/bin/env python2
from __future__ import print_function
from montmul import *
import sys, subprocess, math, random

def get_params(paramfile) :
  infile = open(paramfile, 'r')

  N_raw = infile.readline().strip()
  N = int(N_raw, 16)
  e_raw = infile.readline().strip()
  e = int(e_raw, 16)

  return (N, e, N_raw, e_raw)

def N(raw=False):
  return params[0 if not raw else 2]

def e(raw=False):
  return params[1 if not raw else 3]

def interact(c) :
  global queries
  queries = queries + 1

  assert(c < N())

  # Send ciphertext c to attack target as hex string
  target_in.write( "{0:x}\n".format(c) )
  target_in.flush()

  # Receive time from attack target.
  delta = int( target_out.readline().strip() )
  m_raw = target_out.readline().strip()
  m = int(m_raw, 16)

  return {'time':delta, 'm':m, 'm_raw':m_raw}

def initialise_attack():
  time_table = []
  mp = get_mp(N())

  for i in xrange(1, 10000):
    c = random.randrange(N())
    idict = interact(c)
    # Get the montgomery rep of each m
    idict['mm'] = get_mont_rep(idict['m'], mp)
    idict['tm_0'] = get_mont_rep(1, mp)
    idict['tm_1'] = idict['tm_0'] #TODO: Can we rid ourselves of this?
    time_table.append(idict)
  
  return (mp, time_table)

def oracles(mp, trial):
  O1 = 0
  O2 = 0

  # TODO: Store these results so we don't recompute the square

  # O1 checks if the next iteration will have to reduce on the square if our key bit is 1
  _, red = mont_mul(trial['tm_1'], trial['tm_1'], mp)

  if (red) :
    O1 = 1

  # O2 does the same but with the assumption of bit 0
  _, red = mont_mul(trial['tm_0'], trial['tm_0'], mp)

  if (red) :
    O2 = 1

  trial['O1'] = O1
  trial['O2'] = O2

  return trial

def mean(l):
  assert(len(l) > 0)
  return float(sum(l)) / float(len(l))

def attack() :
  N_bits = int(math.log(N(), 2)) # Usually we'd expect d to be up to N bits long
  H = 1

  # We are given that the max d is b-1 (thus must be at most 64 bits)
  max_d_i = 64

  # Get a random (large) set of timing data with accompanying ciphertexts, messages and montgomery info
  (mp, some_trials) = initialise_attack()

  # We know the first bit is 1, so do the first step
  for t in some_trials:
    t['tm_1'], _ = mont_mul(t['tm_1'], t['tm_1'], mp) # TODO: Required?
    t['tm_1'], _ = mont_mul(t['tm_1'], t['mm'], mp)
    # TODO: Remove me
    t['tm_0'] = "I am not an integer and if you attempt to use me then you will be sorely disappointed and will crash, or possibly not as you are python and you do what you like"

  # Step through square and multiply algo
  for i in xrange(1, max_d_i):
    M1 = [] # O1 = 1
    M2 = [] # O1 = 0
    M3 = [] # O2 = 1
    M4 = [] # O2 = 0

    # do both outcomes for step i based on the key bit previously decided in round i-1
    prev_key_bit = H >> (i-1)
    assert prev_key_bit < 2

    for t in some_trials:
      chosen_t = t['tm_0']
      if prev_key_bit == 1:
        chosen_t = t['tm_1']

        # check that nothing weird has happened to our t value
        assert chosen_t < N()

      t['tm_0'], _ = mont_mul(chosen_t, chosen_t, mp)
      t['tm_1'], _ = mont_mul(t['tm_0'], t['mm'], mp)

      # TODO: Sum here
      t_ = oracles(mp, t)
      # Hopefully, oracles is modifying t in place (but it doesn't really matter... that much)
      assert t_ == t

      # TODO: We can cut away the map operation with F and M
      # Sort into the correct bins
      if t['O1'] == 1:
        M1.append(t)
      else:
        M2.append(t)

      if t['O2'] == 1:
        M3.append(t)
      else:
        M4.append(t)

#    (M1, M2, M3, M4) = oracle_map(some_trials, H, mp)

    F1 = map(lambda x: x['time'], M1)
    F2 = map(lambda x: x['time'], M2)
    F3 = map(lambda x: x['time'], M3)
    F4 = map(lambda x: x['time'], M4)

    mu1 = mean(F1)
    mu2 = mean(F2)
    mu3 = mean(F3)
    mu4 = mean(F4)

#    print(mu1, mu2, mu3, mu4)

    # Move to next bit
    #d = d << 1
    H = H << 1

    # Compare the differences between mu1/2 and mu3/4
    diff12 = abs(mu1-mu2)
    diff34 = abs(mu3-mu4)

    print(diff12, diff34)

    if (diff12 > diff34):
      # Guess H_i = 1
      H = H | 1
    else:
      H = H | 0
    print(bin(H))

  return H

def verify_d(d):
  # TODO: pick some real numbers
  m = 245674544525437553L
  assert(m < N())
  c = pow(m, e(), N())
  m_ = pow(c, d, N())
  return (m == m_)

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
  d = attack()

  # Check our guess
  assert(verify_d(d))

  print("Recovered private key d:\n{0:x}".format(d))

  print("Total target interactions:", queries)

  # Terminate the target process
  target.terminate()

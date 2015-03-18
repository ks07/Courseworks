#!/usr/bin/env python2
from __future__ import print_function
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

  return (delta, m, m_raw)

def time_random_c():
  time_table = []

  for i in xrange(1, 10000):
    c = random.randrange(N())
    (delta, m, m_raw) = interact(c)
    #print(delta, c, m)
    time_table.append((c, m, delta))
  
  return time_table

def oracles(b, m):
  O1 = 0
  O2 = 0

  # TODO: We probably need to mod this?
  #m_temp = (m ** b) ** 2
  m_temp = pow(m, b * 2, N())
  r = (m_temp * m) ** 2

  if (r >= N()) :
    O1 = 1

  r = m_temp ** 2

  if (r >= N()) :
    O2 = 1

  return (O1, O2)

def oracle_map(trials, b):
  #      O1, !O1, O2, !O2
  ret = ([],  [], [],  [])
  for t in trials:
    m = t[1]
    o = oracles(b, m)

    if o[0] == 1:
      ret[0].append(t)
    else:
      ret[1].append(t)

    if o[1] == 1:
      ret[2].append(t)
    else:
      ret[3].append(t)

  return ret

def mean(l):
  assert(len(l) > 0)
  float(sum(l)) / float(len(l))

def attack() :
  N_bits = int(math.log(N(), 2)) # Usually we'd expect d to be up to N bits long
  d = 1 # We know the MSB is 1
  H = 1

  # We are given that the max d is b-1 (thus must be at most 64 bits)
  max_d_i = 64

  some_trials = time_random_c()

  for i in xrange(1, 2):
#    M1 = [] # O1 = 1
#    M2 = [] # O1 = 0
#    M3 = [] # O2 = 1
#    M4 = [] # O2 = 0

    (M1, M2, M3, M4) = oracle_map(some_trials, H)

    F1 = map(lambda x: x[2], M1)
    F2 = map(lambda x: x[2], M2)
    F3 = map(lambda x: x[2], M3)
    F4 = map(lambda x: x[2], M4)
    print(F1)
    mu1 = mean(F1)
    mu2 = mean(F2)
    mu3 = mean(F3)
    mu4 = mean(F4)

    print(mu1, mu2, mu3, mu4)

    # Move to next bit
    d = d << 1
    H = H << 1

    # Guess H_i = 1
    H = H | 1
    

  return d

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

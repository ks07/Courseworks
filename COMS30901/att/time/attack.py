#!/usr/bin/env python2
from __future__ import print_function
from hashlib import sha1
import sys, subprocess, math

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

  # Send ciphertext c to attack target as hex string
  target_in.write( "{0:x}\n".format(c) )
  target_in.flush()

  # Receive time from attack target.
  delta = int( target_out.readline().strip() )
  m_raw = target_out.readline().strip()
  m = int(m_raw, 16)

  return (delta, m, m_raw)

def attack() :
  return 12

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

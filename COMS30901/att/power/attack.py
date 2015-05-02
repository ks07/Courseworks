#!/usr/bin/env python2
from __future__ import print_function
import sys, subprocess, math

def interact(m) :
  global queries
  queries = queries + 1

  pad_bytes = 16

  # Send plaintext m to attack target as hex octet string.
  # Target appears to treat m as little endian, no padding required
  target_in.write( "{0:x}\n".format(m) )
  target_in.flush()

  # Receive comma separated power trace of ints
  vec = [int(v) for v in target_out.readline().strip().split(',')]

  assert (vec[0] == len(vec) - 1), "Received trace length doesn't match samples"

  trace = vec[1:]

  # Receive ciphertext c from attack target.
  c = int( target_out.readline().strip(), 16 )

  return (c, trace)

def attack() :
  (c, trace) = interact(0xabcd)

def launch_target(executable) :
  # Produce a sub-process representing the attack target.
  target = subprocess.Popen( args   = executable,
                             stdout = subprocess.PIPE,
                             stdin  = subprocess.PIPE )

  
  return target

if ( __name__ == "__main__" ) :
  if (len(sys.argv) != 2) :
    print("Usage: attack.py <target executable>")
    sys.exit(1)

  # Launch the attack target sub-process.
  target = launch_target(sys.argv[1])

  # Construct handles to attack target standard input and output.
  target_out = target.stdout
  target_in  = target.stdin

  # Set a global counter of interactions
  queries = 0

  # Execute a function representing the attacker.
  attack()

  # Check our guess
  #assert(verify_m(m))

  #print("Recovered key k:\n{0:x}".format(k))

  print("Total target interactions:", queries)

  # Terminate the target process
  target.terminate()

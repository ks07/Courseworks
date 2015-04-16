#!/usr/bin/env python2
from __future__ import print_function
import sys, subprocess, math

queries = 0

class FaultSpec:
  def __init__(self, r, f, p, i, j):
    self.r = r
    self.f = f
    self.p = p
    self.i = i
    self.j = j

  def __str__(self):
    return '{r},{f},{p},{i},{j}'.format(r=self.r, f=self.f ,p=self.p, i=self.i, j=self.j)

def interact(fault_spec, m):
  global queries
  queries += 1

  # Send fault spec to attack target
  target_in.write( '{0}\n'.format(fault_spec if fault_spec else '') )

  # Send plaintext m to attack target as 128-bit hex octet string
  target_in.write( '{0:0{1}x}\n'.format(m, 32) )
  target_in.flush()

  # Receive ciphertext c from attack target.
  c = int( target_out.readline().strip(), 16 )

  return c

def attack():
  print(interact(None, 0))

if ( __name__ == '__main__' ) :
  if (len(sys.argv) != 2) :
    print('Usage: attack.py <target executable>')
    sys.exit(1)

  # Produce a sub-process representing the attack target.
  target = subprocess.Popen( args   = sys.argv[ 1 ],
                             stdout = subprocess.PIPE,
                             stdin  = subprocess.PIPE )

  # Construct handles to attack target standard input and output.
  target_out = target.stdout
  target_in  = target.stdin

  # Execute a function representing the attacker.
  attack()

  # # Check our guess
  # assert(verify_m(m))

  # # Decode the found m to get the secret
  # s = eme_oaep_decode(I2OSP(m, int(math.ceil(math.log(N(), 256)))))

  # print("Recovered plaintext m:\n{0:x}".format(m))
  # print("Recovered secret s:")
  # s_hex(s)

  # print("Total target interactions:", queries)

  # Terminate the target process
  target.terminate()

#!/usr/bin/env python2
from __future__ import print_function
import sys, subprocess

def get_params(paramfile) :
  infile = open(paramfile, 'r')

  N = int(infile.readline().strip(), 16)
  e = int(infile.readline().strip(), 16)
  ct = int(infile.readline().strip(), 16) # This smells fishy

  return (N, e, ct)

def interact(c) :
  # Send ciphertext c to attack target as hex. TODO: more mystery surrounding octet strings, yet apparently this is fine
  target_in.write( "%x\n" % ( c ) )
  target_in.flush()

  # Receive result code r from attack target.
  r = int( target_out.readline().strip() )

  return r

def attack() :
  # Send the ciphertext we've been given.
  c = params[2]
  print(c)

  # ... then interact with the attack target.
  r = interact( c )

  # Print all of the inputs and outputs.
  print("c = %s" % ( c ))
  print("r = %d" % ( r ))

if ( __name__ == "__main__" ) :
  if (len(sys.argv) != 3) :
    print("Usage: attack.py <target executable> <parameter file>")
    sys.exit()

  # Read param file
  params = get_params(sys.argv[2])

  # Produce a sub-process representing the attack target.
  target = subprocess.Popen( args   = sys.argv[ 1 ],
                             stdout = subprocess.PIPE, 
                             stdin  = subprocess.PIPE )

  # Construct handles to attack target standard input and output.
  target_out = target.stdout
  target_in  = target.stdin

  # Execute a function representing the attacker.
  attack()

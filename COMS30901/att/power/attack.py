#!/usr/bin/env python2
from __future__ import print_function
import sys, subprocess, math
import scipy.io, numpy

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
#  (c, trace) = interact(0xabcd)


  # Try recreating the matlab code
  ws = scipy.io.loadmat('WS2.mat', squeeze_me=True)

  first = 0
  last = 255

  SubBytes = ws['SubBytes']
  byte_Hamming_weight = ws['byte_Hamming_weight']
  traces = ws['traces']

  kbytes = 16
  for b in range(kbytes):
    inputs = ws['inputs'][:,b]
    #inputs = ws['inputs']
  
    print('Predicting intermediate values ...')
    m,n = ws['traces'].shape
  
    key = range(256)
    after_sbox = numpy.zeros((m,256), dtype=numpy.uint8)
  
    for i in range(m):
      xored = inputs[i] ^ key
      after_sbox[i,:] = SubBytes[xored]
  
    key_trace = numpy.zeros((256,n))
  
    # correlation method
    print('Predicting the instantaneous power consumption ...')
    power_consumption = byte_Hamming_weight[after_sbox]
  
    print('Generating the correlation traces ...')
  
    chunksize = 50
    chunks = n / 50
  
    #for i in range(last, last+1):
      #for j in range(chunks,chunks+1):
    for i in range(first, last+1):
      for j in range(1,chunks+1):
        #print(i, j)
        ccarg = numpy.column_stack((traces[:,(j-1)*chunksize:j*chunksize], power_consumption[:,i]))
        cmatrix = numpy.corrcoef(ccarg, rowvar=0)
        #print(numpy.mean(ccarg), numpy.mean(cmatrix), ccarg.shape, cmatrix.shape, cmatrix[7,5], cmatrix[32,12])
        key_trace[i,(j-1)*chunksize:j*chunksize] = cmatrix[chunksize,0:chunksize];
        #print(key_trace[i,(j-1)*chunksize:j*chunksize])
        #print(key_trace.shape, numpy.mean(key_trace))
  
    global kt
    kt = key_trace
  
    # Correct key index should be the one where the trace has the highest correlation.
    prime_suspects, _ = numpy.unravel_index((kt.argmin(), kt.argmax()), kt.shape)
  
    # TODO: What if these don't match?
    assert prime_suspects[0] == prime_suspects[1]
    print(b, prime_suspects[0])
  

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

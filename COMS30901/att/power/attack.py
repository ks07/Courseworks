#!/usr/bin/env python2
from __future__ import print_function
import sys, subprocess, math
import numpy as np

queries = 0
target = None
target_in = None
target_out = None

# Python-ified sbox lifted from http://anh.cs.luc.edu/331/code/aes.py
# Rijndael S-box, wrapped in an ndarray for advanced indexing
sbox = np.asarray([
    0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67,
    0x2b, 0xfe, 0xd7, 0xab, 0x76, 0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59,
    0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0, 0xb7,
    0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1,
    0x71, 0xd8, 0x31, 0x15, 0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05,
    0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75, 0x09, 0x83,
    0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29,
    0xe3, 0x2f, 0x84, 0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b,
    0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf, 0xd0, 0xef, 0xaa,
    0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c,
    0x9f, 0xa8, 0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc,
    0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2, 0xcd, 0x0c, 0x13, 0xec,
    0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19,
    0x73, 0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee,
    0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb, 0xe0, 0x32, 0x3a, 0x0a, 0x49,
    0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
    0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4,
    0xea, 0x65, 0x7a, 0xae, 0x08, 0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6,
    0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a, 0x70,
    0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9,
    0x86, 0xc1, 0x1d, 0x9e, 0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e,
    0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf, 0x8c, 0xa1,
    0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0,
    0x54, 0xbb, 0x16 ])

# Calculate the hamming weights of all 256 possible key values
# There are probably faster ways of computing this, and hard-coding the array would be
# sensible... but this is fast and simple
byte_Hamming_weight = np.asarray([bin(i).count('1') for i in range(256)])

# m should be a list/array of 8 bit integers
def interact(m) :
  global queries
  queries = queries + 1

  pad_bytes = 16

  # Send plaintext m to attack target as hex octet string.
  # No nditer in this numpy version :(
  for b in range(len(m)):
    target_in.write( "{0:0{pad}x}".format(int(m[b]), pad=2) )

  target_in.write("\n")
  target_in.flush()

  # Receive comma separated power trace of ints
  vec = [int(v) for v in target_out.readline().strip().split(',')]

  assert (vec[0] == len(vec) - 1), "Received trace length doesn't match samples"

  # Cut out the length field
  trace = vec[1:]

  # Receive ciphertext c from attack target.
  c = int( target_out.readline().strip(), 16 )

  return (c, trace)

def gather_interactions() :
  # Unfortunately numpy doesn't support 128 bit types
  # Generate 200 messages of 4 32 bit integers (16 bytes)
  # A 'bug'/caveat with the random generator means it can't handle the entire uint64 range
  # nor will it work with signed bounds.
  # Access byte values by using an 8 bit view
  tinfo = np.iinfo(np.uint32)
  inputs = np.random.random_integers(tinfo.min, tinfo.max, (200, 4)).astype(np.uint32).view(np.uint8)

  traces = []

  for m in inputs:
    _, trace = interact(m)
    traces.append(trace)

  traces = np.asarray(traces, dtype=np.uint8)

  return (inputs, traces)

def attack() :
  # Get a set of random inputs and their power traces
  all_inputs, traces = gather_interactions()

  _,n = traces.shape

  # number of measurements (n) must divide the chunksize (50)
  # we only imitate the first round, so take ~10%
  rough = int(math.ceil(float(n / 10) / 50.0)) * 50

  # Reduce the trace measurements
  traces = traces[:,0:rough]

  # Possible key byte values to consider (all of them is a good idea)
  first = 0
  last = 255

  byte_count = 16

  # Output list
  found_key = [None]*byte_count

  # Loop through all 16 bytes of the key
  for b in range(byte_count):
    inputs = all_inputs[:,b]

    print('Predicting intermediate values ...')
    m,n = traces.shape

    key = range(256)
    after_sbox = np.zeros((m,256), dtype=np.uint8)

    for i in range(m):
      xored = inputs[i] ^ key
      after_sbox[i,:] = sbox[xored]

    key_trace = np.zeros((256,n))

    # correlation method
    print('Predicting the instantaneous power consumption ...')
    power_consumption = byte_Hamming_weight[after_sbox]

    print('Generating the correlation traces ...')

    chunksize = 50
    chunks = n / 50

    for i in range(first, last+1):
      for j in range(1,chunks+1):
        ccarg = np.column_stack((traces[:,(j-1)*chunksize:j*chunksize], power_consumption[:,i]))
        cmatrix = np.corrcoef(ccarg, rowvar=0)
        key_trace[i,(j-1)*chunksize:j*chunksize] = cmatrix[chunksize,0:chunksize];

    # Correct key index should be the one where the trace has the highest correlation.
    # Old numpy versions :(
    argmin = key_trace.argmin()
    argmax = key_trace.argmax()
    prime_suspects = [None,None]
    prime_suspects[0], _ = np.unravel_index(argmin, key_trace.shape)
    prime_suspects[1], _ = np.unravel_index(argmax, key_trace.shape)

    # Pick the max by default
    selected = prime_suspects[1]

    print(key_trace.flat[argmin], abs(key_trace.flat[argmin]))
    if (abs(key_trace.flat[argmin]) > key_trace.flat[argmax]):
      # Pick the min if higher magnitude
      selected = prime_suspects[0]

    print('Found key byte #{0:d} = {1:x}'.format(b, selected))
    found_key[b] = selected

  return found_key

def launch_target(executable) :
  # Produce a sub-process representing the attack target.
  global target
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

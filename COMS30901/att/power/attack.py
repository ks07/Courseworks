#!/usr/bin/env python2
from __future__ import print_function
import sys, subprocess, math
import numpy
#import scipy.io
import pickle
np = numpy

queries = 0
target = None
target_in = None
target_out = None

# m should be a list/array of 8 bit integers
def interact(m) :
  global queries
  queries = queries + 1

  pad_bytes = 16

  # Send plaintext m to attack target as hex octet string.
  # Target appears to treat m as little endian, no padding required on 2nd?
  # TODO: Check this works, maybe we need to reverse
  # Trololo no nditer in this numpy version
  for b in range(len(m)):
    target_in.write( "{0:0{pad}x}".format(int(m[b]), pad=2) )


#  target_in.write( "{0:0{pad}x}{1:0{pad}x}{2:0{pad}x}{3:0{pad}x}\n".format(m[0], m[1], m[2], m[3], pad=8))
  target_in.write("\n")
  target_in.flush()

  # Receive comma separated power trace of ints
  vec = [int(v) for v in target_out.readline().strip().split(',')]

  assert (vec[0] == len(vec) - 1), "Received trace length doesn't match samples"

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
#  (c, trace) = interact(0xabcd)

  global inputs
  global traces

  all_inputs, traces = gather_interactions()

  m,n = traces.shape
  
  # n must divide the chunksize (50)
  # we only imitate the first round, so take ~10%
  rough = n / 10
  rough = int(math.ceil(float(rough) / 50.0)) * 50

  traces = traces[:,0:rough]

  print(traces.shape)

  # Try recreating the matlab code
#  ws = scipy.io.loadmat('WS2.mat', squeeze_me=True)
  ridyourselfofme = open('pickled', 'r')
  youcontinuetodisappoint = pickle.load(ridyourselfofme)

  byte_Hamming_weight = youcontinuetodisappoint[0]
  SubBytes = youcontinuetodisappoint[1]

  first = 0
  last = 255

  #SubBytes = ws['SubBytes']
  #byte_Hamming_weight = ws['byte_Hamming_weight']
  #traces = ws['traces']

  print(traces.shape)

  kbytes = 16
  for b in range(kbytes):
    inputs = all_inputs[:,b]
    #inputs = ws['inputs']
  
    print('Predicting intermediate values ...')
    m,n = traces.shape
  
    key = range(256)
    after_sbox = numpy.zeros((m,256), dtype=numpy.uint8)
  
    for i in range(m):
      xored = inputs[i] ^ key
      after_sbox[i,:] = SubBytes.flat[xored]
  
    key_trace = numpy.zeros((256,n))
  
    # correlation method
    print('Predicting the instantaneous power consumption ...')
    power_consumption = byte_Hamming_weight.flat[after_sbox]
  
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
  
    #print(kt.argmin(), kt.argmax(), kt.shape)

    # Correct key index should be the one where the trace has the highest correlation.
    # Old numpy versions :(
    argmin = kt.argmin()
    argmax = kt.argmax()
    prime_suspects = [None,None]
    prime_suspects[0], _ = numpy.unravel_index(argmin, kt.shape)
    prime_suspects[1], _ = numpy.unravel_index(argmax, kt.shape)

    selected = prime_suspects[1]

    if (kt.flat[argmin] > kt.flat[argmax]):
      # Pick the min, higher magnitude
      selected = prime_suspects[0]

    print(b, selected)
  

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

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
  ct_raw = infile.readline().strip()
  ct = int(ct_raw, 16) # This smells fishy

  return (N, e, ct, N_raw, e_raw, ct_raw)

def N(raw=False):
  return params[0 if not raw else 3]

def e(raw=False):
  return params[1 if not raw else 4]

def ct(raw=False):
  return params[2 if not raw else 5]

def interact(c, pad_bytes) :
  global queries
  queries = queries + 1

  # Send ciphertext c to attack target as hex octet string
  target_in.write( "{0:0{1}x}\n".format(c, pad_bytes * 2) )
  target_in.flush()

  # Receive result code r from attack target.
  r = int( target_out.readline().strip() )

  # Interpret result code as B comparison
  interp = (r == 1)

  if (r not in [0,1,2]):
    print("Error code %d!\n" % r)

  return (r, interp)

def ceildiv(a, b):
  # Upside down floor division!
  return -(-a // b)

# Credit to https://stackoverflow.com/questions/16022556/
# Dreams of Python 3.2 on the lab machines abound
def to_bytes(n, length, endianness='big'):
    h = '%x' % n
    s = ('0'*(len(h) % 2) + h).zfill(length*2).decode('hex')
    return s if endianness == 'big' else s[::-1]

def I2OSP(x, xlen):
  assert(x < 256 ** xlen)
  return to_bytes(x, xlen, endianness='big')

# As per RFC3447 appendix B.2.1
def mgf1(Hash, hLen, mgf_seed, mask_len):
  assert(mask_len <= ( 2 ** 32 ) * hLen)
  
  T = ""

  for counter in range(0, ceildiv(mask_len, hLen)):
    C = I2OSP(counter, 4)
    # TODO: Use a fixed hash stem of seed
    T = T + Hash(mgf_seed + C).digest()

  return T[0:mask_len]

def string_xor(x, y):
  assert(len(x) == len(y))
  return ''.join(map( lambda t: chr(ord(t[0]) ^ ord(t[1])) , zip(x, y) ))

def s_hex(s):
  print(''.join(x.encode('hex') for x in s))

# As per RFC3447 section 7.1.2
def eme_oaep_decode(em):
  Hash = sha1
  L = ""
  lHash = Hash(L).digest()
  hLen = len(lHash)
  k = len(em)

  # SHA-1 digests should be 160 bits
  assert(hLen == 160 // 8)

  # Number of octets in mdb
  mdb_len = k - hLen - 1

  # Split the encoded message into Y || maskedSeed || maskedDB
  y     = em[0      : 1     ]
  mseed = em[1      : hLen+1]
  mdb   = em[hLen+1 :       ]

  assert (y == '\x00')
  assert(len(mdb) == mdb_len)

  seedmask = mgf1(Hash, hLen, mdb, hLen)
  seed = string_xor(mseed, seedmask)
  dbmask = mgf1(Hash, hLen, seed, mdb_len)
  db = string_xor(mdb, dbmask)

  lHash_ = db[0:hLen]
  assert (lHash == lHash_)

  db_ = db[hLen:].lstrip('\x00')
  assert (db_[0] == '\x01')

  m = db_[1:]

  print("Decoded secret:")
  s_hex(m)

def attack() :
  k = int(math.ceil(math.log(N(), 256)))
  B = 2 ** (8*(k-1))

  # k should be the number of bytes needed to represent N... which should match the string length
  assert k == len(N(True)) // 2

  # Assume 2B < N
  assert 2 * B < N()

  # Implement attack from https://www.iacr.org/archive/crypto2001/21390229.pdf
  # 1.1
  f1 = 2

  # 1.2
  to_query = pow(f1, e(), N())
  to_query = (to_query * ct()) % N()
  (r, gte_B) = interact(to_query, k)

  # 1.3a
  while (not gte_B):
    f1 = f1 * 2
    
    # 1.2
    to_query = pow(f1, e(), N())
    to_query = (to_query * ct()) % N()
    (r, gte_B) = interact(to_query, k)

  #1.3b
  #print("f1\t", f1);
  # Move to step 2
  
  #2.1
  f2 = ( (N() + B) // B ) * f1 // 2
  #print("f2\t", f2)

  #2.2
  to_query = pow(f2, e(), N())
  to_query = (to_query * ct()) % N()
  (r, gte_B) = interact(to_query, k)
  
  #2.3a
  while (gte_B):
    f2 = f2 + f1 // 2

    #2.2
    to_query = pow(f2, e(), N())
    to_query = (to_query * ct()) % N()
    (r, gte_B) = interact(to_query, k)

  #2.3b
  # Move to step 3

  #3.1
  m_min = ceildiv(N(), f2)
  m_max = (N() + B) // f2
  
  #3.5 TODO: Can we fiddle this condition for one less comparison?
  while (m_max != m_min):
    #3.2
    f_tmp = (2 * B) // (m_max - m_min)
    #3.3
    i = (f_tmp * m_min) // N()
    #3.4
    f3 = ceildiv( (i * N()), m_min)
    to_query = pow(f3, e(), N())
    to_query = (to_query * ct()) % N()
    (r, gte_B) = interact(to_query, k)

    #3.5a
    if (gte_B):
      m_min = ceildiv( (i * N()) + B, f3 )
    #3.5b
    else:
      m_max = ( (i * N()) + B ) // f3

  #print("f3\t%d\n" % (f3))
  print("Plaintext m:\n%x" % m_min)

  return m_min

def verify_m(m):
  c = pow(m, e(), N())
  return (ct() == c)

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
  m = attack()

  # Check our guess
  assert(verify_m(m))

  # Decode the found m to get the secret
  eme_oaep_decode(I2OSP(m, int(math.ceil(math.log(N(), 256)))))

  print("Target queries:", queries)

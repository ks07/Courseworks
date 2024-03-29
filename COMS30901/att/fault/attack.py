#!/usr/bin/env python2
from __future__ import print_function
from Crypto.Cipher import AES
from operator import itemgetter
import sys, subprocess, math, itertools, random
import numpy as np

queries = 0

# Lifted from http://anh.cs.luc.edu/331/code/aes.py
# Rijndael S-box
sbox =  [0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67,
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
         0x54, 0xbb, 0x16]

# Generate the inverse Rijndael S-box
rsbox = [None] * len(sbox)
for i,e in enumerate(sbox):
  rsbox[e] = i

class FaultSpec:
  def __init__(self, r, f, p, i, j):
    self.r = r
    self.f = f
    self.p = p
    self.i = i
    self.j = j

  def __str__(self):
    return '{r},{f},{p},{i},{j}'.format(r=self.r, f=self.f ,p=self.p, i=self.i, j=self.j)

def target_init(exe):
  # Produce a sub-process representing the attack target.
  global target
  target = subprocess.Popen( args   = exe,
                             stdout = subprocess.PIPE,
                             stdin  = subprocess.PIPE )
  return target

def interact(fault_spec, m):
  global queries
  queries += 1

  # Send fault spec to attack target
  target.stdin.write( '{0}\n'.format(fault_spec if fault_spec else '') )

  # Send plaintext m to attack target as 128-bit hex octet string
  target.stdin.write( '{0:0{1}x}\n'.format(m, 32) )
  target.stdin.flush()

  # Receive ciphertext c from attack target.
  c = int( target.stdout.readline().strip(), 16 )

  return c

def verify_key(m, c, found_key) :
  key = np.asarray(found_key, dtype=np.uint8).tostring()

  # Find the ciphertext of m under key
  enc = AES.new(key, AES.MODE_ECB)
  c_test = enc.encrypt(to_bytes(m, 16))

  # Get back as an int... somewhat inelegant
  c_test = int(c_test.encode('hex'), 16)

  return c_test == c

# Credit to https://stackoverflow.com/questions/16022556/
# Dreams of Python 3.2 on the lab machines abound
def to_bytes(n, length, endianness='big'):
    h = '%x' % n
    s = ('0'*(len(h) % 2) + h).zfill(length*2).decode('hex')
    return s if endianness == 'big' else s[::-1]

# Probably a nicer way to do this
def c_to_state(c, byte_count):
  return [ord(b) for b in to_bytes(c, byte_count)]

# Finite field multiplication in GF(2^8)
# Courtesy of https://gist.github.com/bonsaiviking/5571001
def gmul(a, b):
  p = 0
  for c in range(8):
    if b & 1:
      p ^= a
    a <<= 1
    if a & 0x100:
      a ^= 0x11b
    b >>= 1
  return p

# Courtesy of http://en.wikipedia.org/wiki/Rijndael_key_schedule
# AES-128 only needs the first 11 elements
Rcon = [0x8d, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36]

# Takes 4 bytes of the key.
def KeyScheduleCore(r, k_r_1):
  # Get key in byte list form, if not already
  try:
    k_r = c_to_state(k_r_1, 4)
  except TypeError:
    k_r = list(k_r_1)

  # Circular left shift (i.e. put the MSByte on the right)
  k_r = k_r[1:] + k_r[:1]

  # S-box all bytes
  k_r = [sbox[k_byte] for k_byte in k_r]

  # Use rcon with the first byte only
  k_r[0] ^= Rcon[r]

  return k_r

# The key k, and the desired round r
def KeySchedule(k, r):
  # Params for AES-128
  n = 16
  b = 176

  # First part of expanded key is the key
  # Get key in byte list form, if not already
  try:
    k_ex = c_to_state(k, n)
  except TypeError:
    k_ex = list(k)

  assert len(k_ex) == n

  # Set rcon iteration to 1
  i = 1

  while len(k_ex) < n * (r+1):
    # Create the next 4 bytes
    t = k_ex[-4:]
    t = KeyScheduleCore(i, t)
    i += 1
    t = [x ^ y for x,y in zip(t, k_ex[-n:4-n])]

    k_ex += t

    # Create the next 12 bytes
    for _ in range(3):
      t = [x ^ y for x,y in zip(k_ex[-4:], k_ex[-n:4-n])]
      k_ex += t

  return k_ex, k_ex[r*16:(r+1)*16]

def GetKey(k_r, r):
  k_prev = list(k_r)
  while r > 0:
    k_prev = IRK(k_prev, r)
    r -= 1
  return k_prev

# Very helpful diagram of KeySchedule: http://crypto.stackexchange.com/a/1527
def IRK(k_r, r):
  k_prev = [None] * 16

  k_prev[3*4:4*4] = [a ^ b for a,b in zip(k_r[3*4:4*4], k_r[2*4:3*4])]
  k_prev[2*4:3*4] = [a ^ b for a,b in zip(k_r[2*4:3*4], k_r[1*4:2*4])]
  k_prev[1*4:2*4] = [a ^ b for a,b in zip(k_r[1*4:2*4], k_r[0*4:1*4])]
  k_prev[0*4:1*4] = [a ^ b for a,b in zip(k_r[0*4:1*4], KeyScheduleCore(r, k_prev[3*4:4*4]))]

  return k_prev

def stage_1(x, xp, great_key_vault):
  byte_end = 256
  for i_d, d_n_params in enumerate(s1_eqs):
    # Loop through all possible delta values
    for d_n in range(byte_end):
      poss_k = [[] for _ in d_n_params] # 4 bytes per delta, should be defined above
      assert len(poss_k) == 4
      # Loop through all 4 key bytes in this set of equations
      for i, (n, mulfac) in enumerate(d_n_params):
        # Loop through all values for each key byte
        for k_n in range(byte_end):
          res = rsbox[x[n] ^ k_n] ^ rsbox[xp[n] ^ k_n]
          # Temporarily store the key byte's value if it satisfies the equation
          if res == gmul(mulfac, d_n):
            poss_k[i].append(k_n)
      # Should only have 4 solutions at most
      assert all((len(sols) <= 4 for sols in poss_k))
      # If no solutions for any of the equations, discard
      if all(poss_k):
        # Add to the results for this equation set the possible vals of each key byte
        great_key_vault[i_d].append(poss_k)

# 2 f'
def s2_fa(x, xp, k):
  f = rsbox[gmul(14, rsbox[x[0] ^ k[0]] ^ k[0] ^ sbox[k[13] ^ k[9]] ^ Rcon[10]) ^ gmul(11, rsbox[x[13] ^ k[13]] ^ k[1] ^ sbox[k[14] ^ k[10]]) ^ gmul(13, rsbox[x[10] ^ k[10]] ^ k[2] ^ sbox[k[15] ^ k[11]]) ^ gmul(9, rsbox[x[7] ^ k[7]] ^ k[3] ^ sbox[k[12] ^ k[8]])] ^ \
      rsbox[gmul(14, rsbox[xp[0] ^ k[0]] ^ k[0] ^ sbox[k[13] ^ k[9]] ^ Rcon[10]) ^ gmul(11, rsbox[xp[13] ^ k[13]] ^ k[1] ^ sbox[k[14] ^ k[10]]) ^ gmul(13, rsbox[xp[10] ^ k[10]] ^ k[2] ^ sbox[k[15] ^ k[11]]) ^ gmul(9, rsbox[xp[7] ^ k[7]] ^ k[3] ^ sbox[k[12] ^ k[8]])]
  return f

# f'
def s2_fb(x, xp, k):
  f = rsbox[gmul(9, rsbox[x[12]^k[12]] ^ k[12] ^ k[8]) ^ gmul(14, rsbox[x[9] ^ k[9]] ^ k[9] ^ k[13]) ^ gmul(11, rsbox[x[6] ^ k[6]] ^ k[14] ^ k[10]) ^ gmul(13, rsbox[x[3] ^ k[3]] ^ k[15] ^ k[11])] ^ \
      rsbox[gmul(9, rsbox[xp[12] ^ k[12]] ^ k[12] ^ k[8]) ^ gmul(14, rsbox[xp[9] ^ k[9]] ^ k[9] ^ k[13]) ^ gmul(11, rsbox[xp[6] ^ k[6]] ^ k[14] ^ k[10]) ^ gmul(13, rsbox[xp[3] ^ k[3]] ^ k[15] ^ k[11])]
  return f

# f'
def s2_fc(x, xp, k):
  f = rsbox[gmul(13, rsbox[x[8] ^ k[8]] ^ k[8] ^ k[4]) ^ gmul(9, rsbox[x[5] ^ k[5]] ^ k[9] ^ k[5]) ^ gmul(14, rsbox[x[2] ^ k[2]] ^ k[10] ^ k[6]) ^ gmul(11, rsbox[x[15] ^ k[15]] ^ k[11] ^ k[7])] ^ \
      rsbox[gmul(13, rsbox[xp[8] ^ k[8]] ^ k[8] ^ k[4]) ^ gmul(9, rsbox[xp[5] ^ k[5]] ^ k[9] ^ k[5]) ^ gmul(14, rsbox[xp[2] ^ k[2]] ^ k[10] ^ k[6]) ^ gmul(11, rsbox[xp[15] ^ k[15]] ^ k[11] ^ k[7])]
  return f

# 3 f'
def s2_fd(x, xp, k):
  f = rsbox[gmul(11, rsbox[x[4] ^ k[4]] ^ k[4] ^ k[0]) ^ gmul(13, rsbox[x[1] ^ k[1]] ^ k[5] ^ k[1]) ^ gmul(9, rsbox[x[14] ^ k[14]] ^ k[6] ^ k[2]) ^ gmul(14, rsbox[x[11] ^ k[11]] ^ k[7] ^ k[3])] ^ \
      rsbox[gmul(11, rsbox[xp[4] ^ k[4]] ^ k[4] ^ k[0]) ^ gmul(13, rsbox[xp[1] ^ k[1]] ^ k[5] ^ k[1]) ^ gmul(9, rsbox[xp[14] ^ k[14]] ^ k[6] ^ k[2]) ^ gmul(14, rsbox[xp[11] ^ k[11]] ^ k[7] ^ k[3])]
  return f

# Defines the four equations used in stage 1. Required for unpacking stage 1 output.
s1_eqs = (
  # d_1
  ((0,2),  (13,1), (10,1), (7,3) ),
  # d_2
  ((4,1),  (1,1),  (14,3), (11,2)),
  # d_3
  ((8,1),  (5,3),  (2,2),  (15,1)),
  # d_4
  ((12,3), (9,2),  (6,1),  (3,1) )
  )

def stage_2(x, xp, great_key_vault, m, c_valid):
  # Get all possible byte value configurations from joining every valid delta set of every possibly byte value config
  eq_set_vals = itertools.product(*[itertools.chain.from_iterable(itertools.starmap(itertools.product, eq_set)) for eq_set in great_key_vault])

  for combo in eq_set_vals:
    # Join the current key value combination with the equation parameters, flatten the list one level with a chain, and sort into the right order of key bytes to get a possible round key
    # Use itemgetters to get only the key byte index or the key byte value.
    poss_rk = map(itemgetter(1), sorted(itertools.chain.from_iterable([zip(map(itemgetter(0), eq_params),kbyte_val) for eq_params, kbyte_val in zip(s1_eqs, combo)]), key=itemgetter(0)))
    # 2 f'
    fa = gmul(3, s2_fa(x, xp, poss_rk))
    # f'
    fb = gmul(6, s2_fb(x, xp, poss_rk))
    # f'
    fc = gmul(6, s2_fc(x, xp, poss_rk))
    # 3 f'
    fd = gmul(2, s2_fd(x, xp, poss_rk))
    #rint(gmul(3,fa), gmul(6,fb), gmul(6,fc), gmul(2,fd))
    if fa == fb == fc == fd:
      print('Possible round key:')
      print(list(poss_rk))
      # Stage 2 will not identify a single definitely correct round key. Must test each.
      key_guess = GetKey(poss_rk, 10)
      if verify_key(m, c_valid, key_guess):
        return key_guess
  assert False, 'No correct keys identified at the end of stage 2!'

def attack(twofault = False):
  if twofault:
    print('Running two fault attack.')
  else:
    print('Running single fault attack. Grab a coffee...')

  # Pick a random message
  m = random.getrandbits(128)
  #m = 132453297378738698636537746945527344052

  # Get correct ciphertext
  c_valid = interact(None, m)

  # Non-zero fault in round 8, before(0) in SubBytes(1) in state byte 0,0
  fault = FaultSpec(8, 1, 0, 0, 0)

  # Get faulty ciphertext
  c_faulty = interact(fault, m)

  print('Valid ciphertext:', hex(c_valid))
  print('Faulty ciphertext 1:', hex(c_faulty))

  byte_end = 256
  key_bytes = 16

  # Convert correct and faulty ciphertexts into byte list
  x  = c_to_state(c_valid, key_bytes)
  xp = c_to_state(c_faulty, key_bytes)

  assert len(x) == key_bytes
  assert len(xp) == key_bytes

  great_key_vault = [[] for _ in s1_eqs]

  stage_1(x, xp, great_key_vault)

  if twofault:
    # Double fault mode, find the intersection of key_vaults.
    great_key_vault_2 = [[] for _ in s1_eqs]
    c_faulty_2 = interact(fault, m)
    print('Faulty ciphertext 2:', hex(c_faulty_2))
    xp_2 = c_to_state(c_faulty_2, key_bytes)
    assert len(xp_2) == key_bytes
    stage_1(x, xp_2, great_key_vault_2)

    # Find the intersection between the repeats.
    key_guess = [None] * key_bytes

    # Loop through each equation set.
    for eq_params, poss_sets, other_sets in zip(s1_eqs, great_key_vault, great_key_vault_2):
      # Loop through the possibility sets in this equation set
      for (poss_set, other_set) in itertools.product(poss_sets, other_sets):
        in_both = (set(curr_byte).intersection(other_byte) for (curr_byte, other_byte) in zip(poss_set, other_set))
        # Check if all the bytes have matches. This should short circuit the generator where possible!
        if in_both and all(in_both):
          # Recompute as the generator will be empty
          in_both = [set(curr_byte).intersection(other_byte) for (curr_byte, other_byte) in zip(poss_set, other_set)]
          for byte_def, byte_val_set in zip(eq_params, in_both):
            assert len(byte_val_set) == 1, 'Second fault did not eliminate all possibilities'
            key_guess[byte_def[0]] = byte_val_set.pop()
          break

    key_guess = np.asarray(GetKey(key_guess, 10), dtype=np.uint8)
  else:
    # Single fault mode, run stage 2.
    print('Running stage 2...')
    key_guess = stage_2(x, xp, great_key_vault, m, c_valid)
    key_guess = np.asarray(key_guess, dtype=np.uint8)

  # Check our guess
  assert (verify_key(m, c_valid, key_guess)), 'Recovered key appears incorrect'

  return key_guess

if ( __name__ == '__main__' ) :
  if (len(sys.argv) != 2) :
    print('Usage: attack.py <target executable>')
    sys.exit(1)

  target_init(sys.argv[1])

  # Execute a function representing the attacker.
  found_key = attack(twofault = True)

  # Possibly the cleanest way to hex-ify the key array
  key_hex = np.asarray(found_key, dtype=np.uint8).tostring().encode('hex')
  print("Recovered key k:")
  print(key_hex)

  print("Total target interactions:", queries)

  # Terminate the target process
  target.terminate()

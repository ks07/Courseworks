#!/usr/bin/env python2
from __future__ import print_function
import sys, subprocess, math

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

# Rijndael Inverted S-box
rsbox = [0x52, 0x09, 0x6a, 0xd5, 0x30, 0x36, 0xa5, 0x38, 0xbf, 0x40, 0xa3,
         0x9e, 0x81, 0xf3, 0xd7, 0xfb, 0x7c, 0xe3, 0x39, 0x82, 0x9b, 0x2f,
         0xff, 0x87, 0x34, 0x8e, 0x43, 0x44, 0xc4, 0xde, 0xe9, 0xcb, 0x54,
         0x7b, 0x94, 0x32, 0xa6, 0xc2, 0x23, 0x3d, 0xee, 0x4c, 0x95, 0x0b,
         0x42, 0xfa, 0xc3, 0x4e, 0x08, 0x2e, 0xa1, 0x66, 0x28, 0xd9, 0x24,
         0xb2, 0x76, 0x5b, 0xa2, 0x49, 0x6d, 0x8b, 0xd1, 0x25, 0x72, 0xf8,
         0xf6, 0x64, 0x86, 0x68, 0x98, 0x16, 0xd4, 0xa4, 0x5c, 0xcc, 0x5d,
         0x65, 0xb6, 0x92, 0x6c, 0x70, 0x48, 0x50, 0xfd, 0xed, 0xb9, 0xda,
         0x5e, 0x15, 0x46, 0x57, 0xa7, 0x8d, 0x9d, 0x84, 0x90, 0xd8, 0xab,
         0x00, 0x8c, 0xbc, 0xd3, 0x0a, 0xf7, 0xe4, 0x58, 0x05, 0xb8, 0xb3,
         0x45, 0x06, 0xd0, 0x2c, 0x1e, 0x8f, 0xca, 0x3f, 0x0f, 0x02, 0xc1,
         0xaf, 0xbd, 0x03, 0x01, 0x13, 0x8a, 0x6b, 0x3a, 0x91, 0x11, 0x41,
         0x4f, 0x67, 0xdc, 0xea, 0x97, 0xf2, 0xcf, 0xce, 0xf0, 0xb4, 0xe6,
         0x73, 0x96, 0xac, 0x74, 0x22, 0xe7, 0xad, 0x35, 0x85, 0xe2, 0xf9,
         0x37, 0xe8, 0x1c, 0x75, 0xdf, 0x6e, 0x47, 0xf1, 0x1a, 0x71, 0x1d,
         0x29, 0xc5, 0x89, 0x6f, 0xb7, 0x62, 0x0e, 0xaa, 0x18, 0xbe, 0x1b,
         0xfc, 0x56, 0x3e, 0x4b, 0xc6, 0xd2, 0x79, 0x20, 0x9a, 0xdb, 0xc0,
         0xfe, 0x78, 0xcd, 0x5a, 0xf4, 0x1f, 0xdd, 0xa8, 0x33, 0x88, 0x07,
         0xc7, 0x31, 0xb1, 0x12, 0x10, 0x59, 0x27, 0x80, 0xec, 0x5f, 0x60,
         0x51, 0x7f, 0xa9, 0x19, 0xb5, 0x4a, 0x0d, 0x2d, 0xe5, 0x7a, 0x9f,
         0x93, 0xc9, 0x9c, 0xef, 0xa0, 0xe0, 0x3b, 0x4d, 0xae, 0x2a, 0xf5,
         0xb0, 0xc8, 0xeb, 0xbb, 0x3c, 0x83, 0x53, 0x99, 0x61, 0x17, 0x2b,
         0x04, 0x7e, 0xba, 0x77, 0xd6, 0x26, 0xe1, 0x69, 0x14, 0x63, 0x55,
         0x21, 0x0c, 0x7d]

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

def sub_bytes_inv(state):
  return [rsbox[x] for x in state]

# Super cool
#S = [ lambda state, sub_bytes() ]

# Credit to https://stackoverflow.com/questions/16022556/
# Dreams of Python 3.2 on the lab machines abound
def to_bytes(n, length, endianness='big'):
    h = '%x' % n
    s = ('0'*(len(h) % 2) + h).zfill(length*2).decode('hex')
    return s if endianness == 'big' else s[::-1]

# Probably a nicer way to do this
def c_to_state(c):
  return [ord(b) for b in to_bytes(c, 32)]

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

def attack():
  # Pick some fixed message for now
  m = 132453297378738698636537746945527344052

  # Get correct ciphertext
  c_valid = interact(None, m)

  # Non-zero fault in round 8, before(0) in SubBytes(1) in state byte 0,0
  fault = FaultSpec(8, 1, 0, 0, 0)
  
  # Get faulty ciphertext
  c_faulty = interact(fault, m)

  print(hex(c_valid))
  print(hex(c_faulty))

  x  = c_to_state(c_valid)
  xp = c_to_state(c_faulty)

  # First chunk of key bytes k1, k8, k11, k14
  byte_end = 256
  key_bytes = 16

  great_key_vault = [[] for _ in range(key_bytes)]

  for d_1 in range(byte_end):
    poss_k_0 = []
    for k_0 in range(byte_end):
      res = rsbox[x[0] ^ k_0] ^ rsbox[xp[0] ^ k_0]
      if res == gmul(d_1, 2):
        poss_k_0.append(res)
    poss_k_13 = []
    for k_13 in range(byte_end):
      res = rsbox[x[13] ^ k_13] ^ rsbox[xp[13] ^ k_13]
      if res == d_1:
        poss_k_13.append(res)
    poss_k_10 = []
    for k_10 in range(byte_end):
      res = rsbox[x[10] ^ k_10] ^ rsbox[xp[10] ^ k_10]
      if res == d_1:
        poss_k_10.append(res)
    poss_k_7 = []
    for k_7 in range(byte_end):
      res = rsbox[x[7] ^ k_7] ^ rsbox[xp[7] ^ k_7]
      if res == gmul(d_1, 3):
        poss_k_7.append(res)
    
    # If no solutions for any of the equations, discard
    if (not poss_k_0 or not poss_k_13 or not poss_k_10 or not poss_k_7):
      continue
    else:
      great_key_vault[0] += poss_k_0
      great_key_vault[13] += poss_k_13
      great_key_vault[10] += poss_k_10
      great_key_vault[7] += poss_k_7

  for d_2 in range(byte_end):
    poss_k_4 = []
    for k_4 in range(byte_end):
      res = rsbox[x[4] ^ k_4] ^ rsbox[xp[4] ^ k_4]
      if res == d_2:
        poss_k_4.append(res)
    poss_k_1 = []
    for k_1 in range(byte_end):
      res = rsbox[x[1] ^ k_1] ^ rsbox[xp[1] ^ k_1]
      if res == d_2:
        poss_k_1.append(res)
    poss_k_14 = []
    for k_14 in range(byte_end):
      res = rsbox[x[14] ^ k_14] ^ rsbox[xp[14] ^ k_14]
      if res == gmul(3, d_2):
        poss_k_14.append(res)
    poss_k_11 = []
    for k_11 in range(byte_end):
      res = rsbox[x[11] ^ k_11] ^ rsbox[xp[11] ^ k_11]
      if res == gmul(2, d_2):
        poss_k_11.append(res)
    
    # If no solutions for any of the equations, discard
    if (not poss_k_4 or not poss_k_1 or not poss_k_14 or not poss_k_11):
      continue
    else:
      great_key_vault[4] += poss_k_4
      great_key_vault[1] += poss_k_1
      great_key_vault[14] += poss_k_14
      great_key_vault[11] += poss_k_11

  for d_3 in range(byte_end):
    poss_k_8 = []
    for k_8 in range(byte_end):
      res = rsbox[x[8] ^ k_8] ^ rsbox[xp[8] ^ k_8]
      if res == d_3:
        poss_k_8.append(res)
    poss_k_5 = []
    for k_5 in range(byte_end):
      res = rsbox[x[5] ^ k_5] ^ rsbox[xp[5] ^ k_5]
      if res == gmul(3, d_3):
        poss_k_5.append(res)
    poss_k_2 = []
    for k_2 in range(byte_end):
      res = rsbox[x[2] ^ k_2] ^ rsbox[xp[2] ^ k_2]
      if res == gmul(2, d_3):
        poss_k_2.append(res)
    poss_k_15 = []
    for k_15 in range(byte_end):
      res = rsbox[x[15] ^ k_15] ^ rsbox[xp[15] ^ k_15]
      if res == d_3:
        poss_k_15.append(res)
    
    # If no solutions for any of the equations, discard
    if (not poss_k_8 or not poss_k_5 or not poss_k_2 or not poss_k_15):
      continue
    else:
      great_key_vault[8] += poss_k_8
      great_key_vault[5] += poss_k_5
      great_key_vault[2] += poss_k_2
      great_key_vault[15] += poss_k_15

  for d_4 in range(byte_end):
    poss_k_12 = []
    for k_12 in range(byte_end):
      res = rsbox[x[12] ^ k_12] ^ rsbox[xp[12] ^ k_12]
      if res == gmul(3, d_4):
        poss_k_12.append(res)
    poss_k_9 = []
    for k_9 in range(byte_end):
      res = rsbox[x[9] ^ k_9] ^ rsbox[xp[9] ^ k_9]
      if res == gmul(2, d_4):
        poss_k_9.append(res)
    poss_k_6 = []
    for k_6 in range(byte_end):
      res = rsbox[x[6] ^ k_6] ^ rsbox[xp[6] ^ k_6]
      if res == d_4:
        poss_k_6.append(res)
    poss_k_3 = []
    for k_3 in range(byte_end):
      res = rsbox[x[3] ^ k_3] ^ rsbox[xp[3] ^ k_3]
      if res == d_4:
        poss_k_3.append(res)
    
    # If no solutions for any of the equations, discard
    if (not poss_k_12 or not poss_k_9 or not poss_k_6 or not poss_k_3):
      continue
    else:
      great_key_vault[12] += poss_k_12
      great_key_vault[9] += poss_k_9
      great_key_vault[6] += poss_k_6
      great_key_vault[3] += poss_k_3

  for i in range(key_bytes):
    print(i, len(great_key_vault[i]))

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

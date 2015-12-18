#!/usr/bin/env python

import random

# with open('gen.ass', 'w') as f:
#     inlist = ['    addi r{0:d},{1:d}\n'.format(i % 32, random.randint(0, 0xFFFF)) for i in range(256)]
#     inlist.append('    halt')
#     f.writelines(inlist)


# inlist = []
# with open('gen.ass', 'w') as f:
#     for i in range(256):
#         inlist.extend(['    addi r{0:d},{1:d}\n'.format((i*3 + j) % 16, random.randint(0, 0xFFFF)) for j in range(3)])
#         inlist.extend(['    ld r{0:d},r{1:d},r{2:d}\n'.format(16 + ((i*2 + j) % 8), 30, 31) for j in range(2)])
#     inlist.append('    halt')
#     f.writelines(inlist)



with open('gen.ass', 'w') as f:
    inlist = ['    movi r{0:d},{1:d}\n'.format(1, random.randint(0, 0xFFFF)) for i in range(256)]
    inlist.append('    halt')
    f.writelines(inlist)

#!/usr/bin/env python

import random

with open('gen.ass', 'w') as f:
    inlist = ['    addi r{0:d},{1:d}\n'.format(i % 32, random.randint(0, 0xFFFF)) for i in range(256)]
    inlist.append('    halt')
    f.writelines(inlist)

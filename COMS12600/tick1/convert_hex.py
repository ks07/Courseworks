#!/usr/bin/python

import sys
import re

if len(sys.argv) < 3:
    print "Usage:\n    python convert_hex.py INFILE OUTFILE\n"
    quit()

infile = sys.argv[1]
outfile = sys.argv[2]

fout = open(outfile, "w")

last_seg = None

for line in open(infile).readlines():
    m = re.match(r'([0-9a-fA-F]{4})([0-9a-fA-F]{4}):\s*(.*)', line)

    if m is not None:
        # This record in the Intel hex format specifies the top 2 bytes of the address
        seg = int(m.group(1),16)
        if seg != last_seg:
            last_seg = seg
            checksum = 256-(6 + ((seg>>8)&0xFF) + (seg&0xFF))
            fout.write(":02000004{0:04x}{1:02x}\n".format(seg, checksum))

        offset = int(m.group(2),16)
        hexes = m.group(3).split()

        checksum_1 = len(hexes) + ((offset>>8)&0xFF) + (offset&0xFF)

        checksum = -((sum(map(lambda x: int(x, 16), hexes)) + checksum_1)&0xFF)+256

        fout.write(":{0:02x}{1:04x}00{2}{3:02x}\n".format(len(hexes), offset, "".join(hexes), checksum))

# End record
fout.write(":00000001FF\n")

fout.close()

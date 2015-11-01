#!/usr/bin/env python

from itertools import izip_longest
import numpy as np

from StatefulComponent import StatefulComponent

# itertools recipe
def grouper(iterable, n, fillvalue=None):
    "Collect data into fixed-length chunks or blocks"
    # grouper('ABCDEFG', 3, 'x') --> ABC DEF Gxx
    args = [iter(iterable)] * n
    return izip_longest(fillvalue=fillvalue, *args)

class RegisterFile(StatefulComponent):
    """ A register file, holding 32 general purpose registers. """

    def __init__(self):
        self._state = np.zeros(32, dtype=np.uint32)
        self._state_nxt = np.zeros_like(self._state)

    def diff(self):
        """ Prints any changes to state. """
        diff = self._state_nxt - self._state
        out = []
        for r in (r for (r,d) in enumerate(diff) if d != 0):
            out.append('r{0:02d}: {1:08x} ({1:d}) => {2:08x} ({2:d})'.format(r, self._state[r], self._state_nxt[r]))
        return "\n".join(out)

    def __str__(self):
        lines = ['Register File:']
        for (i,a),(j,b),(k,c),(l,d) in grouper(enumerate(self._state_nxt), 4):
            lines.append("r{0:>2d}: {1:>10d}\tr{2:>2d}: {3:>10d}\tr{4:>2d}: {5:>10d}\tr{6:>2d}: {7:>10d}".format(i,a,j,b,k,c,l,d))
        return "\n".join(lines)

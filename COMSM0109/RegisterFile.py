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
    """ A register file, holding 32 general purpose registers, and a scoreboard for validity."""

    SCBD_IND = 32 # Index of scoreboard for register value validity.
    
    def __init__(self):
        self._state = np.zeros(33, dtype=np.uint32)
        self._state_nxt = np.zeros_like(self._state)
        self._state[self.SCBD_IND] = 0xFFFFFFFF
        self._state_nxt[self.SCBD_IND] = 0xFFFFFFFF
#        self._scbd_ctrs = np.zeros(32, dtype=np.int8) # Holds scoreboard counters WAIT WE DONT NEED THIS
# SET SCBD IF ROB SEES NO MORE WRITES FOR GIVEN REG

    def diff(self):
        """ Prints any changes to state. """
        diff = self._state_nxt - self._state
        out = []
        for r in (r for (r,d) in enumerate(diff) if d != 0):
            out.append('r{0:02d}: {1:08x} ({1:d}) => {2:08x} ({2:d})'.format(r, self._state[r], self._state_nxt[r]))
        return "\n".join(out)

    def __str__(self):
        lines = ['Register File:']
        for (i,a),(j,b),(k,c),(l,d) in grouper(enumerate(self._state_nxt[:self.SCBD_IND]), 4):
            lines.append("r{0:>2d}: {1:>10d}\tr{2:>2d}: {3:>10d}\tr{4:>2d}: {5:>10d}\tr{6:>2d}: {7:>10d}".format(i,a,j,b,k,c,l,d))
        lines.append('scoreboard 0b{0:032b}'.format(self._state[self.SCBD_IND]))
        return "\n".join(lines)

    def resetScoreboard(self):
        """ Marks all registers as clean. """
        self._state[self.SCBD_IND] = 0xFFFFFFFF
    
    def markScoreboard(self, ri, dirty):
        """ Marks an entry in the reg file as dirty (or not). """
        print 'HOLY BATMAN',ri,dirty
        scbd = self._state[self.SCBD_IND]
        if dirty:
            new = scbd & (0xFFFFFFFF ^ (1 << ri))
        else:
            new = scbd | (1 << ri)
        if scbd == new:
            print 'WARNING: Scoreboard update unnecessary!', ri, dirty
        self.update(self.SCBD_IND, new) #TODO: What happens when there's a dependency at the same time?
        self._state[self.SCBD_IND] = new;
        
    def validScoreboard(self, ri):
        """ Checks if the scoreboard has a value marked as dirty. """
        print 'scoreboard', bin(self._state[self.SCBD_IND])
        return self._state[self.SCBD_IND] & (1 << ri)
    

#!/usr/bin/env python

import numpy as np

from StatefulComponent import StatefulComponent

class Memory(StatefulComponent):
    """ A memory. """

    def __init__(self, mem_file):
        self._state = np.fromfile(mem_file, dtype=np.uint32)
        self._state_nxt = self._state.copy()

    def diff(self):
        """ Prints any changes to state. """
        diff = self._state_nxt - self._state
        out = []
        for r in (r for (r,d) in enumerate(diff) if d != 0):
            out.append('{0:02d}: {1:08x} ({1:d}) => {2:08x} ({2:d})'.format(r, self._state[r], self._state_nxt[r]))
        return "\n".join(out)

    def __str__(self):
        # TODO: Too much to print
        return str(self._state)

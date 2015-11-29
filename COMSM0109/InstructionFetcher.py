#!/usr/bin/env python

import numpy as np
from StatefulComponent import StatefulComponent

class InstructionFetcher(StatefulComponent):
    """ The instruction fetching stage. State is the address we are loading from. (i.e. PC) Also required count. """

    PCI = 0 # Index of PC
    FCI = 1 # Index of fetch count
    
    def __init__(self, mem, width):
        self._state = np.zeros(2, dtype=np.uint32)
        self._state_nxt = np.zeros_like(self._state)
        # Need to backup before changes (to undo bad predictions)
        self._old_state = np.zeros_like(self._state)
        # Need a handle to memory (read-only access!)
        self._mem = mem
        # Set the fetch count for the first iter.
        self._state[self.FCI] = width

    def diff(self):
        """ Prints the instruction now in the decode stage. """
        return "" #TODO

    def __str__(self):
        return 'PC = {0:d}'.format(self._state[self.PCI])

    # Need to override, to store old PC
    def update(self, addr, val):
        """ Stores the previous state when being updated. """
        self._old_state[self.PCI] = self._state_nxt[self.PCI]
        return super(self.__class__, self).update(addr, val)

    def restore(self):
        """ Restores the previously saved state, when branch prediction was wrong. """
        self._state_nxt[self.PCI] = self._old_state[self.PCI]

    def fetchIns(self): #TODO: Fix name conflict nicely!
        """ Does the fetch from memory (with implied cache)"""
        return self._mem[self._state[self.PCI]:self._state[self.PCI]+self._state[self.FCI]]

    def inc(self):
        """ Increments the PC. """
        self._state_nxt[self.PCI] = self._state[self.PCI] + self._state[self.FCI]

#!/usr/bin/env python

import numpy as np

class StatefulComponent(object):
    """ A component in the CPU that holds some state. """

    def advstate(self):
        """ Set the current state to next state. """
        np.copyto(self._state, self._state_nxt, casting='no')

    # Need to be careful that we don't try to read from the wrong state - careful planning of architecture!
    def update(self, addr, val):
        """ Sets a single element of the state. """
        self._state_nxt[addr] = val

    def __setitem__(self, key, value):
        # Allows indexed update. (e.g. rf[1] = 10)
        #print "Set", key, "from", self[key], "to", value
        self.update(key, value)

    def fetch(self, addr):
        """ Gets a single element of the state. """
        # TODO: Is this the right state to read from?
        return self._state[addr]

    def __getitem__(self, key):
        # Allows indexed retrieval.
        return self.fetch(key)

    def __len__(self):
        return len(self._state)

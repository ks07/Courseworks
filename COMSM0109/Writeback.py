#!/usr/bin/env python

from Instruction import Instruction

class Writeback(object):
    """ The register writeback stage. We do have state, but nothing in a Numpy array! """

    def __init__(self, reg):
        self._ins = Instruction.NOP()
        self._ins_nxt = Instruction.NOP()
        # Need a handle to register file
        self._reg = reg

    def __str__(self):
        return 'Now in writeback: {0:s}'.format(str(self._ins))

    def updateInstruction(self, ins):
        """ Puts an instruction on the stage input. """
        self._ins_nxt = ins;

    def writeback(self):
        """ Performs the writeback stage. """
        for reg, val in self._ins.getWBOutput():
            print '* Writeback stage is storing {0:d} in r{1:d} for {2:s}.'.format(val, reg, str(self._ins))
            self._reg[reg] = val

    def advstate(self):
        """ Advances state, like a StatefulComponent. """
        self._ins = self._ins_nxt

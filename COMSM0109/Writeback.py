#!/usr/bin/env python

from Instruction import Instruction

class Writeback(object):
    """ The register writeback stage. We do have state, but nothing in a Numpy array! """

    def __init__(self, rob):
        self._ins = Instruction.NOP()
        self._ins_nxt = Instruction.NOP()
        # Need handle to reorder buffer
        self._rob = rob

    def __str__(self):
        return 'Now in writeback: {0:s}'.format(str(self._ins))

    def updateInstruction(self, ins):
        """ Puts an instruction on the stage input. """
        self._ins_nxt = ins;

    def writeback(self):
        """ Puts values into ROB. """
        self._rob.insWriteback(self._ins)

    def advstate(self):
        """ Advances state, like a StatefulComponent. """
        self._ins = self._ins_nxt

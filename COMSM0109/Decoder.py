#!/usr/bin/env python

import numpy as np
from StatefulComponent import StatefulComponent
from Instruction import Instruction
from InstructionFormats import FORMATS

class Decoder(StatefulComponent):
    """ A decode unit. State is the current instruction in this stage, and an indicator for load stalling. """

    RLD_IND = 1
    NO_LD = 64
    
    def __init__(self, regfile):
        self._state = np.zeros(2, dtype=np.uint32)
        self._state_nxt = np.zeros_like(self._state)
        # Decode stage reads from register file.
        self._reg = regfile

    def diff(self):
        """ Prints the instruction now in the decode stage. """
        return "" #TODO

    def __str__(self):
        return 'Decoding now: {0:08x} => {1:s}'.format(self._state[0], str(self._decode(self._state[0])))


    def decode(self):
        """ Wrapper for decode, using input from state. Returns the instruction object. """
        ins = self._decode(self._state[0])

        # Store the output reg.
        #TODO: Nicer check of load
        ldreg = ins.getOutReg() if ins.getOutReg() is not None and ins.getOpc().startswith('ld') else self.NO_LD
        self.update(self.RLD_IND, ldreg)

        # If the previously decoded ins was a load, check if there is a RAW dependency.
        # if self._state[self.RLD_IND]] < 32:
        if self._state[self.RLD_IND] in ins.getRegValMap():
            print '* v---Inserting a bubble to avoid data hazard from RAW dependency after a load.' #TODO: Print order
            # Need to stall both this and fetch stages to wait for the bubble.
            self.update(0, self._state[0]) #TODO: This could be problematic if stages are re-ordered!
            return Instruction.NOP() #TODO: Can the interaction between stages be handled by the stages, not CPU?
        return ins

    def _decode(self, word):
        """ Decodes a given word; return an Instruction object represented by word. """
        group = word >> 26 # All instructions start with a possibly unique 6 bit ID
        diff = word & 0x1F # Where ins not identified uniquely by group, the 5 LSBs should differentiate

        possible = [(opc, frmt) for opc, frmt in FORMATS.iteritems() if frmt[0] == group]

        if not possible:
            # If invalid instruction, either the program is going to branch before this
            # is executed, the program has a bug, or the sim has a bug!
            # The first possibility is not an error, so replace instruction with something we can pass!
            return Instruction.NOP(word)
        elif len(possible) == 1:
            opc, frmt = possible[0]
            if diff != frmt[-1] and not isinstance(frmt[-1], basestring):
                return Instruction.NOP(word)
            # The Instruction constructor deals with splitting args.
            return Instruction(opc, frmt, word, self._reg)
        else:
            for opc, frmt in possible:
                if frmt[-1] == diff:
                    return Instruction(opc, frmt, word, self._reg)
            raise ValueError('Could not decode instruction. Perhaps PC has entered a data segment?', word,  '{:032b}'.format(word))

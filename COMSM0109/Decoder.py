#!/usr/bin/env python

import numpy as np
from StatefulComponent import StatefulComponent
from Instruction import Instruction

class Decoder(StatefulComponent):
    """ A decode unit. State is the current instruction in this stage, and a record of registers that are dirty. """

    RBI_OFS = 0
    RBD_OFS = 32
    INS_IND = 64
    
    def __init__(self, regfile):
        # First 32 elements represent bypassed inputs, next 32 are dirty flags, final element for current ins.
        self._state = np.zeros(self.INS_IND + 1, dtype=np.uint32)
        self._state_nxt = np.zeros_like(self._state)
        # Decode stage reads from register file.
        self._reg = regfile

    def diff(self):
        """ Prints the instruction now in the decode stage. """
        return "" #TODO

    def __str__(self):
        return 'Decoding now: {0:08x} => {1:s}'.format(self._state[0], str(self.decode()))

    # Should match that from assembler.py -- move to a separate file!
    formats = {
        'nop': (0,0),
        'add': (1,'r','r','r',0),
        'sub': (1,'r','r','r',1),
        'mul': (1,'r','r','r',2),
        'and': (1,'r','r','r',3),
        'or': (1,'r','r','r',4),
        'xor': (1,'r','r','r',5),
        'mov': (1,'r','r',6),
        'shl': (1,'r','r','r',8),
        'shr': (1,'r','r','r',9),
        'addi': (2,'r','i',0),
        'subi': (2,'r','i',1),
        'muli': (2,'r','i',2),
        'andi': (2,'r','i',3),
        'ori': (2,'r','i',4),
        'xori': (2,'r','i',5),
        'movi': (2,'r','i',6),
        'moui': (2,'r','i',7),
        'ld': (3,'r','r','r',0),
        'st': (4,'r','r','r',0),
        'br': (5,'i',0),
        'bz': (6,'r','i',0),
        'bn': (7,'r','i',0),
        'beq': (8,'r','r','i'),
        'bge': (9,'r','r','i'),
    }

    def decode(self):
        """ Wrapper for decode, using input from state. Returns the instruction object. """
        # Needs to adjust dirty flags
        for ri in range(self.RBD_OFS, self.RBD_OFS + 32):
            if self._state[ri] > 0:
                self._state[ri] -= 1
        return self._decode(self._state[self.INS_IND])

    # Need a wrapper for the reg file, simulating the bypass mux (for data hazards).
    class RegisterWrapper(object):
        """ Wraps the register file, decode specific. """
        def __init__(self, regfile, dstate):
            self._reg = regfile;
            self._dstate = dstate;
    
        def __getitem__(self, ri):
            # Check if the register is marked as dirty.
            if self._dstate[Decoder.RBD_OFS + ri] == 0:
                return self._reg[ri]
            else:
                return self._dstate[Decoder.RBI_OFS + ri]

    def _decode(self, word):
        """ Decodes a given word; return an Instruction object represented by word. """
        group = word >> 26 # All instructions start with a possibly unique 6 bit ID
        diff = word & 0x1F # Where ins not identified uniquely by group, the 5 LSBs should differentiate

        possible = [(opc, frmt) for opc, frmt in Decoder.formats.iteritems() if frmt[0] == group]

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

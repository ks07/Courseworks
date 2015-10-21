#!/usr/bin/env python

import sys, numpy as np

class Instruction:
    """ An instruction. """

    def __init__(self, opcode, frmt, word):
        self._opcode = opcode
        # Note the similarity to gen_ins in assember!
        operands = []
        shift = 26
        for arg in frmt[1:-1]:
            if arg == 'r':
                shift -= 5
                mask = 0x1F
            elif arg == 'i':
                shift -= 16
                mask = 0xFFFF
            else:
                raise ValueError("Bad argument type when trying to get operand from word.", arg, opcode, frmt, word)
            operands.append((word >> shift) & mask)
        self._operands = tuple(operands)

    def getOpc(self):
        return self._opcode

    def getOpr(self):
        return self._operands

    def execute(self):
        # TODO: Should this just be a big if or do we want polymorphism?
        print self
        return

    def __str__(self):
        # This is the implode_ins function in the assembler!
        return "{} {}".format(self._opcode, ",".join(str(a) for a in self._operands))

class Decoder:
    """ A decode unit. """

    # Should match that from assembler.py -- move to a separate file!
    formats = {
        'nop': (0,0),
        'add': (1,'r','r','r',0),
        'sub': (1,'r','r','r',1),
        'mul': (1,'r','r','r',2),
        'addi': (2,'r','i',0),
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
    
    def decode(self, word):
        """ Decodes a given word; return an Instruction object represented by word. """
        group = word >> 26 # All instructions start with a possibly unique 6 bit ID
        diff = word & 0x1F # Where ins not identified uniquely by group, the 5 LSBs should differentiate

        possible = [(opc, frmt) for opc, frmt in Decoder.formats.iteritems() if frmt[0] == group]

        if not possible:
            # TODO: Better error display
            raise ValueError('Could not decode instruction. Perhaps PC has entered a data segment?', word)
        elif len(possible) == 1:
            opc, frmt = possible[0]
            if diff != frmt[-1] and not isinstance(frmt[-1], basestring):
                raise ValueError('Could not decode instruction. Perhaps PC has entered a data segment?', word)
            # The Instruction constructor deals with splitting args.
            return Instruction(opc, frmt, word)
        else:
            for opc, frmt in possible:
                if frmt[-1] == diff:
                    return Instruction(opc, frmt, word)
            

class CPU:
    """ A simple scalar processor simulator. Super-scalar coming soon... """

    def __init__(self, mem_file):
        self._mem = np.fromfile(mem_file, dtype=np.uint32)
        print "Loaded", self._mem.size, "words into memory."
        self._reg = np.zeros(32, dtype=np.uint32)
        self._pc = 0
        self._decoder = Decoder()

    def step(self):
        # Fetch
        word = self._mem[self._pc]
        # Increment PC
        self._pc += 1
        # Decode
        ins = self._decoder.decode(word)
        # Execute
        ins.execute()

def start(mem_file):
    cpu = CPU(mem_file)
    while True:
        sys.stdin.readline()
        cpu.step()

if __name__ == '__main__' :
    mem_file = sys.argv[1]
    start(mem_file)

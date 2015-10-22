#!/usr/bin/env python

from itertools import izip_longest
import sys, numpy as np

# itertools recipe
def grouper(iterable, n, fillvalue=None):
    "Collect data into fixed-length chunks or blocks"
    # grouper('ABCDEFG', 3, 'x') --> ABC DEF Gxx
    args = [iter(iterable)] * n
    return izip_longest(fillvalue=fillvalue, *args)

class Instruction:
    """ An instruction. """

    @staticmethod
    def _decf2strf(frmt):
        """ Converts a decode format tuple to a python str.format compatible format string. Static method. """
        strf = []
        for a in frmt[1:-1]:
            if a == 'r':
                strf.append('r{:d}')
            else:
                strf.append('{:d}')
        return "{} " + ",".join(strf)

    def __init__(self, opcode, frmt, word):
        self._opcode = opcode
        self._frmt_str = Instruction._decf2strf(frmt) # If we subclass this becomes unnecessary?
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
        # Need to cover the case where the end of the instruction is an immediate
        if frmt[-1] == 'i':
            operands.append(word & 0xFFFF)
        self._operands = tuple(operands)

    def getOpc(self):
        return self._opcode

    def getOpr(self):
        return self._operands

    def execute(self):
        # TODO: Should this just be a big if or do we want polymorphism?
        print "Executing", self # Morbid
        return

    def __str__(self):
        # This is the implode_ins function in the assembler!
        return self._frmt_str.format(self._opcode, *self._operands)

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

class StatefulComponent:
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
        self.update(key, value)

    def fetch(self, addr):
        """ Gets a single element of the state. """
        # TODO: Is this the right state to read from?
        return self._state_nxt[addr]

    def __getitem__(self, key):
        # Allows indexed retrieval.
        return self.fetch(key)

    def __len__(self):
        return len(self._state)

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
        lines = []
        for (i,a),(j,b),(k,c),(l,d) in grouper(enumerate(self._state_nxt), 4):
            lines.append("{0:>2d}: {1:>10d}\t{2:>2d}: {3:>10d}\t{4:>2d}: {5:>10d}\t{6:>2d}: {7:>10d}".format(i,a,j,b,k,c,l,d))
        return "\n".join(lines);

class CPU:
    """ A simple scalar processor simulator. Super-scalar coming soon... """

    def __init__(self, mem_file):
        # State (current and next)
        self._mem = Memory(mem_file)
        print "Loaded", len(self._mem), "words into memory."
        self._reg = RegisterFile()
        self._pc = 0
        self._pc_nxt = 0

        # Non-stateful components
        self._decoder = Decoder()

    def _exec(self, ins):
        # Not sure if we want to keep this logic here...
        print ins
        opc = ins.getOpc()
        opr = ins.getOpr()
        # TODO: Order these sensibly
        if opc == 'movi':
            self._reg[opr[0]] = opr[1]
        elif opc == 'moui':
            self._reg[opr[0]] |= (opr[1] << 16)
        elif opc == 'ld':
            # TODO: De-dupe the r_base + r_offset logic?
            self._reg[opr[0]] = self._mem[ self._reg[opr[1]] + self._reg[opr[2]] ]
        elif opc == 'add':
            self._reg[opr[0]] = self._reg[opr[1]] + self._reg[opr[2]]
        elif opc == 'st':
            self._mem[ self._reg[opr[1]] + self._reg[opr[2]] ] = self._reg[opr[0]]
        elif opc == 'addi':
            self._reg[opr[0]] += opr[1]
        elif opc == 'bge':
            # TODO: Pipeline will ruin this...
            if self._reg[opr[0]] >= self._reg[opr[1]]:
                self._pc = opr[2]
        elif opc == 'br':
            # TODO: And this...
            self._pc = opr[0]
        elif opc == 'nop':
            print "Doing NOP'in!"

    def _update(self):
        """ Updates the state of all components, ready for the next iteration. """
        # TODO: Expand state to others (i.e. pc)
        self._reg.advstate();

    def step(self):
        # Fetch
        word = self._mem[self._pc]
        # Increment PC
        self._pc += 1
        # Decode
        ins = self._decoder.decode(word)
        # Execute
        self._exec(ins)
        # Update states
        print self._reg
        self._update()

    def dump(self, start, end):
        for addr in range(start, end + 1):
            print "{0:08x} | {1:08x} ({1:})".format(addr, self._mem[addr])

def start(mem_file):
    cpu = CPU(mem_file)
    # Manual stepping
    while True:
        usr = sys.stdin.readline().strip()
        if usr.startswith('d'):
            args = usr.split(' ')[1:]
            cpu.dump(int(args[0], 0), int(args[1], 0))
        elif usr.startswith('r'):
            print "Resetting CPU..."
            cpu = CPU(mem_file)
        else:
            cpu.step()

if __name__ == '__main__' :
    mem_file = sys.argv[1]
    start(mem_file)

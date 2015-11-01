#!/usr/bin/env python

from itertools import izip_longest
import sys, numpy as np

# itertools recipe
def grouper(iterable, n, fillvalue=None):
    "Collect data into fixed-length chunks or blocks"
    # grouper('ABCDEFG', 3, 'x') --> ABC DEF Gxx
    args = [iter(iterable)] * n
    return izip_longest(fillvalue=fillvalue, *args)

class Instruction(object):
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
        # Need to cover end = imm
        if frmt[-1] == 'i':
            strf.append('{:d}')
        return ("{} " + ",".join(strf)).rstrip()

    @staticmethod
    def NOP(debug = False):
        """ Gets a NOP instruction, as a placeholder. If debug is set, the instruction should never be executed, and will throw an error if attempted. """
        if debug:
            return Instruction('dnop', (0,1), debug) # Abuse the word field to hold the potentially invalid inst
        else:
            return Instruction('nop', (0,0), 0)

    def __init__(self, opcode, frmt, word, predicted=False):
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
        # Store the source word, for debug.
        self._word = word;
        # Store if the branch predictor has decided to take this
        self.predicted = predicted

    def getOpc(self):
        return self._opcode

    def getOpr(self):
        return self._operands

    def getWord(self):
        """ Get word, for debugging! """
        return self._word

    def __str__(self):
        # This is the implode_ins function in the assembler!
        return self._frmt_str.format(self._opcode, *self._operands)

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
        lines = ['Register File:']
        for (i,a),(j,b),(k,c),(l,d) in grouper(enumerate(self._state_nxt), 4):
            lines.append("r{0:>2d}: {1:>10d}\tr{2:>2d}: {3:>10d}\tr{4:>2d}: {5:>10d}\tr{6:>2d}: {7:>10d}".format(i,a,j,b,k,c,l,d))
        return "\n".join(lines)

class BranchPredictor(StatefulComponent):
    """ A static branch predictor. """

    def predict(self, pc, ins):
        """ Returns true if we predict the branch will be taken. """
        if ins.getOpc() == 'br':
            # Unconditional, always taken
            return True
        else:
            dest = ins.getOpr()[-1]
            return dest < pc

class Decoder(StatefulComponent):
    """ A decode unit. State is just the current instruction in this stage. """

    def __init__(self):
        self._state = np.zeros(1, dtype=np.uint32)
        self._state_nxt = np.zeros_like(self._state)

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
        return self._decode(self._state[0])

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
            return Instruction(opc, frmt, word)
        else:
            for opc, frmt in possible:
                if frmt[-1] == diff:
                    return Instruction(opc, frmt, word)
            raise ValueError('Could not decode instruction. Perhaps PC has entered a data segment?', word,  '{:032b}'.format(word))

class InstructionFetcher(StatefulComponent):
    """ The instruction fetching stage. State is the address we are loading from. (i.e. PC) """

    def __init__(self, mem):
        self._state = np.zeros(1, dtype=np.uint32)
        self._state_nxt = np.zeros_like(self._state)
        # Need to backup before changes (to undo bad predictions)
        self._old_state = np.zeros_like(self._state)
        # Need a handle to memory (read-only access!)
        self._mem = mem

    def diff(self):
        """ Prints the instruction now in the decode stage. """
        return "" #TODO

    def __str__(self):
        return 'PC = {0:d}'.format(self._state[0])

    # Need to override, to store old PC
    def update(self, addr, val):
        """ Stores the previous state when being updated. """
        self._old_state[0] = self._state_nxt[0]
        return super(self.__class__, self).update(addr, val)

    def restore(self):
        """ Restores the previously saved state, when branch prediction was wrong. """
        self._state_nxt[0] = self._old_state[0]

    def fetchIns(self): #TODO: Fix name conflict nicely!
        """ Does the fetch from memory (with implied cache) """
        return self._mem[self._state[0]]

    def inc(self):
        """ Increments the PC. """
        self._state_nxt[0] = self._state[0] + 1

class CPU(object):
    """ A simple scalar processor simulator. Super-scalar coming soon... """

    def __init__(self, mem_file):
        # State (current and next)
        self._mem = Memory(mem_file)
        print "Loaded", len(self._mem), "words into memory."
        self._reg = RegisterFile()
        self._ins = Instruction.NOP()
        self._ins_nxt = Instruction.NOP()

        # Stage components (also with state!)
        self._fetcher = InstructionFetcher(self._mem)
        self._decoder = Decoder()
        # Execute step performed here for now TODO: Execute Unit/ALU

        # Time counter
        self._simtime = 0

        # Branch predictor (part of decode stage)
        self._predictor = BranchPredictor()

    def _exec(self, ins):
        print '* Execute stage is performing {0:s} (including reads/writes and logic, yikes!)'.format(str(ins))

        # Not sure if we want to keep this logic here...
        opc = ins.getOpc()
        opr = ins.getOpr()
        if opc == 'nop':
            pass
        elif opc == 'dnop':
            raise ValueError('Could not decode instruction. Perhaps PC has entered a data segment?', ins.getWord())
        elif opc == 'add':
            self._reg[opr[0]] = self._reg[opr[1]] + self._reg[opr[2]]
        elif opc == 'sub':
            self._reg[opr[0]] = self._reg[opr[1]] - self._reg[opr[2]]
        elif opc == 'mul':
            self._reg[opr[0]] = self._reg[opr[1]] * self._reg[opr[2]]
        elif opc == 'and':
            self._reg[opr[0]] = self._reg[opr[1]] & self._reg[opr[2]]
        elif opc == 'or':
            self._reg[opr[0]] = self._reg[opr[1]] | self._reg[opr[2]]
        elif opc == 'xor':
            self._reg[opr[0]] = self._reg[opr[1]] ^ self._reg[opr[2]]
        elif opc == 'mov':
            self._reg[opr[0]] = self._reg[opr[1]]
        elif opc == 'shl':
            self._reg[opr[0]] = self._reg[opr[1]] << self._reg[opr[2]]
        elif opc == 'shr':
            self._reg[opr[0]] = self._reg[opr[1]] >> self._reg[opr[2]]
        elif opc == 'addi':
            self._reg[opr[0]] += opr[1]
        elif opc == 'subi':
            self._reg[opr[0]] -= opr[1]
        elif opc == 'muli':
            self._reg[opr[0]] *= opr[1]
        elif opc == 'andi':
            self._reg[opr[0]] &= opr[1]
        elif opc == 'ori':
            self._reg[opr[0]] |= opr[1]
        elif opc == 'xori':
            self._reg[opr[0]] ^= opr[1]
        elif opc == 'movi':
            self._reg[opr[0]] = opr[1]
        elif opc == 'moui':
            self._reg[opr[0]] |= (opr[1] << 16)
        elif opc == 'ld':
            # TODO: De-dupe the r_base + r_offset logic?
            self._reg[opr[0]] = self._mem[ self._reg[opr[1]] + self._reg[opr[2]] ]
        elif opc == 'st':
            self._mem[ self._reg[opr[1]] + self._reg[opr[2]] ] = self._reg[opr[0]]
        elif opc == 'br':
            # Should do nothing as we will always predict this!
            #self._branch(opr[0])
            print "* ...but br is always taken, so this is a nop!"
            pass
        elif opc == 'bz':
            self._branch(self._reg[opr[0]] == 0, ins.predicted, opr[1])
        elif opc == 'bn':
            # Need to switch on the top bit (rather than <0), as we're storing as unsigned!
            self._branch(self._reg[opr[0]] >> 31, ins.predicted, opr[1])
        elif opc == 'beq':
            self._branch(self._reg[opr[0]] == self._reg[opr[1]], ins.predicted, opr[2])
        elif opc == 'bge':
            self._branch(self._reg[opr[0]] >= self._reg[opr[1]], ins.predicted, opr[2])
        else:
            print "WARNING: Unimplemented opcode:", opc

    def _update(self):
        """ Updates the state of all components, ready for the next iteration. """
        print '\n---------Stepping---------\n'
        self._reg.advstate()
        self._mem.advstate()
        self._decoder.advstate()
        self._fetcher.advstate()
        self._ins = self._ins_nxt
        # Need to increment time
        self._simtime += 1

    def _branch(self, cond, pred, dest):
        """ Clears the pipeline and does the branch (if necessary!). """
        if cond and not pred:
            # Should have taken, but did not.
            print "* ...and the predictor was wrong, taking branch and clearing pipeline inputs!"
            self._fetcher.update(0, dest) # Update the PC to point to the new address
            self._decoder.update(0, 0) # Empty the decode register
            self._ins_nxt = Instruction.NOP() # Empty the execute instruction reg
        elif not cond and pred:
            # Shouldn't have taken, but did.
            print "* ...and the predictor was wrong, restoring PC and clearing pipeline inputs!"
            self._fetcher.restore() # Load the original PC value from before prediction
            self._decoder.update(0, 0) # Empty the decode register
            self._ins_nxt = Instruction.NOP() # Empty the execute instruction reg
        else:
            print "* ...and the predictor was right, so this was a nop!"

    def _usePrediction(self, pred, branch):
        """ Uses the prediction to set the fetch target prematurely. Must run after fetch has set decoder input. """
        if pred:
            print "* Predictor (in decode stage) decided branch {0:s} will be taken.".format(str(branch))
            dest = branch.getOpr()[-1] # TODO: Pass in?
            # Set the new dest
            self._fetcher.update(0, dest)
            # The branch predictor will switch the input to the decode stage to a nop (whatever was there is after the branch and we don't want it!)
            self._decoder.update(0, Instruction.NOP().getWord()) # WARNING! There is now a dependency that this must run AFTER fetch passes to decode!
            # Need to tell the execute unit that the branch was taken already
            branch.predicted = True

    def step(self):
        """ Performs all the logic for the current sim time, and steps to the next. """
        print '\n---Performing Cycle Logic---\n'

        # Fetch Stage
        toDecode = self._fetcher.fetchIns()
        print '* Fetch stage loaded from mem, passing {0:08x} to decode stage.'.format(toDecode)

        # Set PC for next time step
        self._fetcher.inc()
        print '* Fetch stage incremented PC.'

        # Pass return values to simulate movement between stages
        self._decoder.update(0, toDecode) # Note this should only affect state for next time (won't pass through)
        # This is a simulator internal step (akin to driving reg input w/out clocking), no print!

        # Decode Stage
        toExecute = self._decoder.decode()
        print '* Decode stage determined the instruction is {0:s}, passing to execution unit'.format(str(toExecute))

        # TODO: Nicer condition
        if toExecute.getOpc().startswith('b'):
            # Predictor as part of decode
            prediction = self._predictor.predict(self._fetcher[0], toExecute)
            self._usePrediction(prediction, toExecute)
            # Handles printing

        # Pass to execute
        self._ins_nxt = toExecute
        # Sim internal

        # Execute Stage (this might undo all the previous steps, if we branch!)
        self._exec(self._ins)
        # Handles printing

        # In theory, everything before this stage should have only changed the 'future' state.
        # Update states (increment sim time)
        self._update()

    def displayState(self):
        # Display state after this step
        print "Sim Time: ", self._simtime
        print self._fetcher
        print self._decoder
        print 'Now executing:', self._ins
        print self._reg

    def dump(self, start, end):
        for addr in range(start, end + 1):
            print "{0:08x} | {1:08x} ({1:})".format(addr, self._mem[addr])

def clearTerm(msg = ''):
    """ Clears terminal using ANSI escape sequence. """
    print "\x1b[2J\x1b[H" + msg

def start(mem_file):
    cpu = CPU(mem_file)
    cpu.displayState()
    # Manual stepping
    while True:
        usr = sys.stdin.readline().strip()
        if usr.startswith('d'):
            args = usr.split(' ')[1:]
            cpu.dump(int(args[0], 0), int(args[1], 0))
        elif usr.startswith('r'):
            clearTerm('Resetting CPU...')
            cpu = CPU(mem_file)
        else:
            cpu.step()
            cpu.displayState()

if __name__ == '__main__' :
    # Ignore overflow warnings - we expect it!
    np.seterr(over='ignore')
    mem_file = sys.argv[1]
    start(mem_file)

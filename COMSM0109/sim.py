#!/usr/bin/env python

import sys, numpy as np

from Instruction import Instruction
from StatefulComponent import StatefulComponent
from Memory import Memory
from RegisterFile import RegisterFile
from BranchPredictor import BranchPredictor
from Decoder import Decoder
from InstructionFetcher import InstructionFetcher

class CPU(object):
    """ A simple scalar processor simulator. Super-scalar coming soon... """

    def __init__(self, mem_file):
        # State (current and next)
        self._mem = Memory(mem_file)
        print "Loaded", len(self._mem), "words into memory."
        self._reg = RegisterFile()
        self._ins = Instruction.NOP()
        self._ins_nxt = Instruction.NOP()
        self._macc = Instruction.NOP()
        self._macc_nxt = Instruction.NOP()
        self._wb = Instruction.NOP()
        self._wb_nxt = Instruction.NOP()

        # Stage components (also with state!)
        self._fetcher = InstructionFetcher(self._mem)
        self._decoder = Decoder(self._reg)
        # Execute step performed here for now TODO: Execute Unit/ALU

        # Time counter
        self._simtime = 0

        # Branch predictor (part of decode stage)
        self._predictor = BranchPredictor()

    def _exec(self):
        ins = self._ins
        
        print '* Execute stage is performing {0:s} (including reads/writes and logic, yikes!)'.format(str(ins))

        # Not sure if we want to keep this logic here...
        opc = ins.getOpc()
        opr = ins.getOpr()
        val = ins.getVal()

        outReg = opr[0] if len(opr) > 0 else None# True for almost all opcodes
        outAddr = None
        
        if opc == 'nop':
            outReg = None
            pass
        elif opc == 'dnop':
            raise ValueError('Could not decode instruction. Perhaps PC has entered a data segment?', ins.getWord())
        elif opc == 'add':
            outVal = val[1] + val[2]
        elif opc == 'sub':
            outVal = val[1] - val[2]
        elif opc == 'mul':
            outVal = val[1] * val[2]
        elif opc == 'and':
            outVal = val[1] & val[2]
        elif opc == 'or':
            outVal = val[1] | val[2]
        elif opc == 'xor':
            outVal = val[1] ^ val[2]
        elif opc == 'mov':
            outVal = val[1]
        elif opc == 'shl':
            outVal = val[1] << val[2]
        elif opc == 'shr':
            outVal = val[1] >> val[2]
        elif opc == 'addi':
            outVal = val[0] + opr[1]
        elif opc == 'subi':
            outVal = val[0] - opr[1]
        elif opc == 'muli':
            outVal = val[0] * opr[1]
        elif opc == 'andi':
            outVal = val[0] & opr[1]
        elif opc == 'ori':
            outVal = val[0] | opr[1]
        elif opc == 'xori':
            outVal = val[0] ^ opr[1]
        elif opc == 'movi':
            outVal = val[1]
        elif opc == 'moui':
            outVal = val[0] | (opr[1] << 16)
        elif opc == 'ld':
            # TODO: De-dupe the r_base + r_offset logic?
            # TODO: Nicer handling of val/mem/writeback in this case
#            outVal = self._mem[ val[1] + val[2] ]
            outReg = None # TODO: lol, not true
            outAddr = val[1] + val[2]
            outVal = None # TODO: plz
        elif opc == 'st':
            outReg = None
            outAddr = val[1] + val[2]
            outVal = val[0] #TODO: Oh please no
#            self._mem[ val[1] + val[2] ] = val[0]
        elif opc == 'br':
            # Should do nothing as we will always predict this!
            outReg = None
            #self._branch(opr[0])
            print "* ...but br is always taken, so this is a nop!"
            pass
        elif opc == 'bz':
            outReg = None
            self._branch(val[0] == 0, ins.predicted, opr[1])
        elif opc == 'bn':
            # Need to switch on the top bit (rather than <0), as we're storing as unsigned!
            outReg = None
            self._branch(val[0] >> 31, ins.predicted, opr[1])
        elif opc == 'beq':
            outReg = None
            self._branch(val[0] == val[1], ins.predicted, opr[2])
        elif opc == 'bge':
            outReg = None
            self._branch(val[0] >= val[1], ins.predicted, opr[2])
        else:
            outReg = None
            print "WARNING: Unimplemented opcode:", opc

        if not outReg is None:
            ins.setWBOutput(outReg, outVal)
        if not outAddr is None:
            ins.setMemOperation(outAddr, outVal)
        return ins

    def _update(self):
        """ Updates the state of all components, ready for the next iteration. """
        print '\n---------Stepping---------\n'
        self._reg.advstate()
        self._mem.advstate()
        self._decoder.advstate()
        self._fetcher.advstate()
        self._ins = self._ins_nxt
        self._wb = self._wb_nxt
        self._macc = self._macc_nxt
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

    def _memaccess(self):
        """ Performs the memory access stage. """
        memop = self._macc.getMemOperation()
        if memop:
            addr,write = memop
            if write:
                print '* Memory access stage wrote {0:d} to address {1:d} for {2:s}.'.format(write, addr, str(self._macc))
                self._mem[addr] = write
            else:
                val = self._mem[addr]
                print '* Memory access stage read {0:d} from address {1:d} for {2:s}.'.format(val, addr, str(self._macc))
                self._macc.setWBOutput(self._macc.getOpr()[0], val) # TODO: This will be broken by weird loads!
        return self._macc

    def _writeback(self):
        """ Performs the writeback stage. """
        for reg, val in self._wb.getWBOutput():
            print '* Writeback stage is storing {0:d} in r{1:d} for {2:s}.'.format(val, reg, str(self._wb))
            self._reg[reg] = val

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
        print '* Decode stage determined the instruction is {0:s}, reading any input registers and passing to execution unit'.format(str(toExecute))

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
        toMacc = self._exec()
        # Handles printing

        # Pass to memory access
        self._macc_nxt = toMacc

        # Memory access stage
        toWriteback = self._memaccess()
        
        # Pass to writeback
        self._wb_nxt = toWriteback

        # Writeback stage
        self._writeback()
        
        # In theory, everything before this stage should have only changed the 'future' state.
        # Update states (increment sim time)
        self._update()

    def displayState(self):
        # Display state after this step
        print "Sim Time: ", self._simtime
        print self._fetcher
        print self._decoder
        print 'Now executing:', self._ins
        print 'Now in memory access:', self._macc
        print 'Now in writeback:', self._wb
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

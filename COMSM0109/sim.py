#!/usr/bin/env python

import sys, numpy as np

from Instruction import Instruction
from StatefulComponent import StatefulComponent
from Memory import Memory
from RegisterFile import RegisterFile
from BranchPredictor import BranchPredictor
from Decoder import Decoder
from InstructionFetcher import InstructionFetcher
from Executor import Executor
from MemoryAccess import MemoryAccess
from Writeback import Writeback

class CPU(object):
    """ A simple scalar processor simulator. Super-scalar coming soon... """

    def __init__(self, mem_file):
        # State (current and next)
        self._mem = Memory(mem_file)
        print "Loaded", len(self._mem), "words into memory."
        self._reg = RegisterFile()

        # Stage components (also with state!)
        self._fetcher = InstructionFetcher(self._mem)
        self._decoder = Decoder(self._reg)
        self._executor = Executor(self) # Requires a reference to us, for branches
        self._memaccess = MemoryAccess(self._mem, self._executor) # Requires a ref to executor, for forwarding
        self._writeback = Writeback(self._reg)

        # Time counter
        self._simtime = 0

        # Branch predictor (part of decode stage)
        self._predictor = BranchPredictor()

    def _update(self):
        """ Updates the state of all components, ready for the next iteration. """
        print '\n---------Stepping---------\n'
        self._reg.advstate()
        self._mem.advstate()
        self._fetcher.advstate()
        self._decoder.advstate()
        self._executor.advstate()
        self._memaccess.advstate()
        self._writeback.advstate()
        # Need to increment time
        self._simtime += 1

    def _branch(self, cond, pred, dest):
        """ Clears the pipeline and does the branch (if necessary!). """
        if cond and not pred:
            # Should have taken, but did not.
            print "* ...and the predictor was wrong, taking branch and clearing pipeline inputs!"
            self._fetcher.update(0, dest) # Update the PC to point to the new address
            self._decoder.update(0, 0) # Empty the decode register
            self._executor.invalidateInstruction() # Empty the execute instruction reg
        elif not cond and pred:
            # Shouldn't have taken, but did.
            print "* ...and the predictor was wrong, restoring PC and clearing pipeline inputs!"
            self._fetcher.restore() # Load the original PC value from before prediction
            self._decoder.update(0, 0) # Empty the decode register
            self._executor.invalidateInstruction() # Empty the execute instruction reg
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
        else:
            print "* Predictor (in decode stage) decided branch {0:s} will not be taken.".format(str(branch))

    def step(self):
        """ Performs all the logic for the current sim time, and steps to the next. """
        print '\n---Performing Cycle Logic---\n'

        # Fetch Stage
        toDecode = self._fetcher.fetchIns()
        print '* Fetch stage loaded from mem, passing {0:08x} to decode stage.'.format(toDecode)

        # Pass return values to simulate movement between stages
        self._decoder.update(0, toDecode) # Note this should only affect state for next time (won't pass through)
        # This is a simulator internal step (akin to driving reg input w/out clocking), no print!

        # Decode Stage
        toExecute = self._decoder.decode()
        print '* Decode stage determined the instruction is {0:s}, reading any input registers and passing to execution unit'.format(str(toExecute))

        # TODO: Nasty hack, we don't really want to compare like this...
        # If the decoder is stalling, don't increment PC, hold the current value.
        if toExecute.getWord() == self._decoder[0]:
            # Set PC for next time step
            self._fetcher.inc()
            print '* Fetch stage incremented PC.'

        # TODO: Nicer condition
        if toExecute.getOpc().startswith('b'):
            # Predictor as part of decode
            prediction = self._predictor.predict(self._fetcher[0], toExecute)
            self._usePrediction(prediction, toExecute)
            # Handles printing

        # Pass to execute
        self._executor.updateInstruction(toExecute)

        # Execute Stage (this might undo all the previous steps, if we branch!)
        toMacc = self._executor.execute()
        # Handles printing

        # Pass to memory access
        self._memaccess.updateInstruction(toMacc)

        # Memory access stage
        toWriteback = self._memaccess.memaccess()

        # Pass to writeback
        self._writeback.updateInstruction(toWriteback)

        # Writeback stage
        self._writeback.writeback()

        # In theory, everything before this stage should have only changed the 'future' state.
        # Update states (increment sim time)
        self._update()

    def displayState(self):
        # Display state after this step
        print "Sim Time: ", self._simtime
        print self._fetcher
        print self._decoder
        print self._executor
        print self._memaccess
        print self._writeback
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

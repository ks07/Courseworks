#!/usr/bin/env python

import sys, numpy as np

from itertools import izip_longest

from random import shuffle

from Instruction import Instruction
from Memory import Memory
from RegisterFile import RegisterFile
from BranchPredictor import BranchPredictor
from Decoder import Decoder
from InstructionFetcher import InstructionFetcher
from ExecuteUnit import ExecuteUnit

class CPU(object):
    """ A simple scalar processor simulator. Super-scalar coming soon... """

    def __init__(self, mem_file):
        # State (current and next)
        self._mem = Memory(mem_file)
        print "Loaded", len(self._mem), "words into memory."
        self._reg = RegisterFile()

        self._decwidth = 2
        
        # Initial stage components.
        self._fetcher = InstructionFetcher(self._mem, self._decwidth)

        self._decoder = Decoder(self._reg, self._decwidth)

        # Superscalar stage components.
        self._eu = [
            ExecuteUnit(0, self._mem, self._reg, self),
            ExecuteUnit(1, self._mem, self._reg, self)
        ]

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
        for eu in self._eu:
            eu.advstate()
        # Need to increment time
        self._simtime += 1

    def _branch(self, cond, pred, dest):
        """ Clears the pipeline and does the branch (if necessary!). """
        if cond and not pred:
            # Should have taken, but did not.
            print "* ...and the predictor was wrong, taking branch and clearing pipeline inputs!"
            self._fetcher.update(0, dest) # Update the PC to point to the new address
            self._decoder.update(0, 0) # Empty the decode register
            for eu in self._eu:
                eu.invalidateExecute() # Empty the execute instruction reg
        elif not cond and pred:
            # Shouldn't have taken, but did.
            print "* ...and the predictor was wrong, restoring PC and clearing pipeline inputs!"
            self._fetcher.restore() # Load the original PC value from before prediction
            self._decoder.update(0, 0) # Empty the decode register
            for eu in self._eu:
                eu.invalidateExecute() # Empty the execute instruction reg
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

    def halt(self):
        """ Halts the simulation. """
        print "Program has halted the simulation!"
        if check_file:
            print "Running check."
            check_vars = {
                'mem': self._mem,
                'reg': self._reg
            }
            execfile(check_file, check_vars)
        sys.exit(0)

    def step(self):
        """ Performs all the logic for the current sim time, and steps to the next. """
        print '\n---Performing Cycle Logic---\n'
        
        # Fetch Stage (will fetch as many as has been requested by decode)
        toDecodeList = self._fetcher.fetchIns()
        for toDecode in toDecodeList:
            print '* Fetch stage loaded from mem, passing {0:08x} to decode stage.'.format(toDecode)

        # Tell fetch stage how much we need to replace next cycle.
        self._fetcher[self._fetcher.FCI] = len(toDecodeList)
        self._fetcher.inc()

        # Pass fetched to decode
        self._decoder.queueInstructions(toDecodeList)

        # Get issued instructions from decoder.
        issued = self._decoder.decode()

        print 'decoded', issued

#        print '* Decode stage determined the instruction is {0:s}, reading any input registers and passing to execution unit'.format(str(toExecuteA))

        # # TODO: Nasty hack, we don't really want to compare like this...
        # # If the decoder is stalling, don't increment PC, hold the current value.
        # if toExecuteA.getWord() == self._decoderA[0]:
        #     # Set PC for next time step
        #     self._fetcher.inc()
        #     print '* Fetch stage incremented PC.'

        # # TODO: Nicer condition
        # if toExecute.getOpc().startswith('b'):
        #     # Predictor as part of decode
        #     prediction = self._predictor.predict(self._fetcher[0], toExecute)
        #     self._usePrediction(prediction, toExecute)
        #     # Handles printing


        # Issue instructions to execute units #TODO: Targeted EUs (e.g. ALU, branch, Mem)
        shuffle(issued) # Shuffle to flag up bugs!
        for i,(eu,ins) in enumerate(izip_longest(self._eu, issued, fillvalue=Instruction.NOP())):
            print 'EU', i, ins
            eu.execute(ins)

        # In theory, everything before this stage should have only changed the 'future' state.
        # Update states (increment sim time)
        self._update()

    def displayState(self):
        # Display state after this step
        print "Sim Time: ", self._simtime
        print self._fetcher
        print self._decoder
        print self._eu
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
    if len(sys.argv) > 2:
        check_file = sys.argv[2]
    else:
        check_file = False;
    if len(sys.argv) > 1:
        mem_file = sys.argv[1]
        start(mem_file)
    else:
        print 'Must supply a filename to load into memory!'

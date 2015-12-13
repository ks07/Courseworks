#!/usr/bin/env python

import sys, numpy as np

from itertools import izip_longest

from random import shuffle

from Instruction import Instruction
from Memory import Memory
from RegisterFile import RegisterFile
from BranchPredictor import BranchPredictor
from Decoder import Decoder
from DecoderSimple import DecoderSimple
from InstructionFetcher import InstructionFetcher
from ExecuteUnit import ExecuteUnit
from BranchUnit import BranchUnit
from ReservationStation import ReservationStation

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

        #self._decoder = Decoder(self._reg, self._decwidth)
        self._decoder = DecoderSimple(self._reg, self._decwidth)

        self._rs = ReservationStation('All', 2, self._reg, 3)

        # Superscalar stage components.
        self._eu = [
            ExecuteUnit(0, self._mem, self._reg, self),
            ExecuteUnit(1, self._mem, self._reg, self)
        ] # General purpose EUs
        # Much simpler to handle branches if they all go through a single EU
        self._bru = BranchUnit(64, self._mem, self._reg, self) # Branch unit
        # Seperate EU for loads and stores
        self._lsu = ExecuteUnit(32, self._mem, self._reg, self) # Load/Store unit

        # For iteration
        self._subpipes = tuple(self._eu + [self._bru, self._lsu])

        # Time counter
        self._simtime = 0

        # Branch predictor (part of decode stage)
        self._predictor = BranchPredictor()

        # Halt flag
        self._haltpending = False

    def _update(self):
        """ Updates the state of all components, ready for the next iteration. """
        print '\n---------Stepping---------\n'
        self._reg.advstate()
        self._mem.advstate()
        self._fetcher.advstate()
        self._decoder.advstate()
        self._rs.advstate()
        for eu in self._subpipes:
            eu.advstate()
        # Need to increment time
        self._simtime += 1

    def bypassBack(self, age, reg, val):
        """ Bypasses results back to everywhere relevant (currently only RS) """
        self._rs.bypassBack(age, reg, val)
        
    def _branch(self, cond, pred, dest):
        """ Clears the pipeline and does the branch (if necessary!). """
        # Need to tell decoder that the branch has been resolved, so blocking can stop
        self._decoder.branchResolved()
        self._rs.branchResolved()
        if cond and not pred:
            # Should have taken, but did not.
            print "* ...and the predictor was wrong, taking branch and clearing pipeline inputs!"
            self._fetcher.update(0, dest) # Update the PC to point to the new address
            self._decoder.pipelineClear()
            self._rs.pipelineClear()
            for eu in self._subpipes:
                eu.invalidateExecute() # Empty the execute instruction reg
            self._reg.resetScoreboard()
        elif not cond and pred:
            # Shouldn't have taken, but did.
            print "* ...and the predictor was wrong, restoring PC and clearing pipeline inputs!"
            self._fetcher.restore() # Load the original PC value from before prediction
            self._decoder.pipelineClear()
            self._rs.pipelineClear()
            for eu in self._subpipes:
                eu.invalidateExecute() # Empty the execute instruction reg
            self._reg.resetScoreboard()
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
            self._decoder.pipelineClear()
#            self._decoder.update(0, Instruction.NOP().getWord()) # WARNING! There is now a dependency that this must run AFTER fetch passes to decode!
#            self._decoder.update(1, Instruction.NOP().getWord()) # WARNING! There is now a dependency that this must run AFTER fetch passes to decode!
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
        toDecodeList, pc = self._fetcher.fetchIns()
        for i,toDecode in enumerate(toDecodeList):
            print '* Fetch stage loaded from mem, passing ({0:d}): {1:08d} to decode stage.'.format(pc+i, toDecode)


        # Get issued instructions from decoder.
#        issuedALU, issuedBRU, issuedLSU = self._decoder.decode()
        issued = self._decoder.issue()

        # Pass fetched to decode
        self._decoder.queueInstructions(toDecodeList, range(len(toDecodeList)) + pc)
        
        # Need to stall the fetcher, if decoder is stalling.
        # BUT: Fetcher will already have fetched the next ins, and will inc for next clock.
        # Need to tell fetcher to go back to the previous instructs.
#        self._fetcher.inc(len(issuedALU) + len(issuedBRU) + len(issuedLSU))
        self._fetcher.inc(len(issued))

#       print 'decoded', issuedALU, issuedBRU, issuedLSU
#       print 'decoded', issued


        # LOL RESERVATION STATION SAYS FUCK YOU
#        big_issue = issuedALU + issuedBRU + issuedLSU
        issuedALU = issuedBRU = issuedLSU = []
        big_issue = issued

        issuedALU = self._rs.dispatch()
#        print self._rs._state_nxt
        stallingRS = self._rs.queueInstructions(big_issue) # THIS NEEDS TO GO 2ND, OOPSIE

        if stallingRS:
            print 'STALLING'
            # Need to stall previous stages
            self._decoder.stall()
            self._fetcher.stall()
        
#        print '* Decode stage determined the instruction is {0:s}, reading any input registers and passing to execution unit'.format(str(toExecuteA))

        # TODO: I'm not sure this works completely correctly
        if self._haltpending or (issuedBRU and issuedBRU[0].isHalt()):
            print 'HALT TIME'
            if issuedBRU:
                issuedBRU[0] = Instruction.NOP()
            # If we are halting, wait for all pipes to clear before issue
            self._haltpending = True
            self._fetcher.update(self._fetcher.FCI, 0)
            if not any((u.hasInstructions() for u in self._subpipes)):
                self.halt()

        # Issue instructions to execute units #TODO: Targeted EUs (e.g. ALU, branch, Mem)
        shuffle(issuedALU) # Shuffle to flag up bugs!
        for i,(eu,ins) in enumerate(izip_longest(self._eu, issuedALU, fillvalue=Instruction.NOP())):
            print 'EU', i, ins
            eu.execute(ins)

        if not issuedLSU:
            issuedLSU = [Instruction.NOP()]
        for ins in issuedLSU:
            print 'LSU', ins
            self._lsu.execute(ins)

        # Need to execute with a nop to actually step the bru pipeline.
        if not issuedBRU:
            issuedBRU = [Instruction.NOP()]
        for ins in issuedBRU:
            print 'BRU', ins
            if ins.isBranch():
                # Predictor as part of decode
                prediction = self._predictor.predict(self._fetcher[0], ins)
                self._usePrediction(prediction, ins)
            # Handles printing
            self._bru.execute(ins)

        # In theory, everything before this stage should have only changed the 'future' state.
        # Update states (increment sim time)
        self._update()

    def displayState(self):
        # Display state after this step
        print "Sim Time: ", self._simtime
        print self._fetcher
        print self._decoder
        print self._rs
        for eu in self._subpipes:
            print eu
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
        elif usr.startswith('a'):
            # Show assembly for operand (decode operand)
            arg = int(usr.split(' ')[1], 0)
            try:
                print cpu._decoder._decode(arg)
            except:
                print 'Not an instruction (dnop)'
        elif usr.startswith('c'):
            # Continue for given number of cycles
            arg = int(usr.split(' ')[1], 0)
            while arg:
                cpu.step()
                arg -= 1
                print '<CONTINUE COMPLETE>'
                cpu.displayState()
        elif usr.startswith('e'):
            # Eval
            arg = usr.split(' ', 1)[1]
            print eval(arg, globals(), locals())
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

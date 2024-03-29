#!/usr/bin/env python

import sys, numpy as np

from itertools import izip_longest

from random import shuffle

from Instruction import Instruction
from Memory import Memory
from RegisterFile import RegisterFile
from DecoderSimple import DecoderSimple
from InstructionFetcher import InstructionFetcher
from ExecuteUnit import ExecuteUnit
from BranchUnit import BranchUnit
from LoadStoreUnit import LoadStoreUnit
from ReservationStation import ReservationStation
from ReorderBuffer import ReorderBuffer

class CPU(object):
    """ A simple scalar processor simulator. Super-scalar coming soon... """

    def __init__(self, mem_file):
        # State (current and next)
        self._mem = Memory(mem_file)
        print "Loaded", len(self._mem), "words into memory."
        self._reg = RegisterFile()

        # The almighty reorder buffer, may he save our dependent souls
        self._rob = ReorderBuffer(16, self._reg, self._mem, self)
        
        self._decwidth = 4
        
        # Initial stage components.
        self._fetcher = InstructionFetcher(self._mem, self._decwidth)

        #self._decoder = Decoder(self._reg, self._decwidth)
        self._decoder = DecoderSimple(self._reg, self._decwidth, self._rob, self)

        self._rs = ReservationStation('All', self._reg, 6, self._rob)

        # Superscalar stage components.
        self._eu = [
            ExecuteUnit(0, self._mem, self, self._rob),
            ExecuteUnit(1, self._mem, self, self._rob)
        ] # General purpose EUs
        # Much simpler to handle branches if they all go through a single EU
        self._bru = BranchUnit(64, self, self._rob) # Branch unit
        # Seperate EU for loads and stores
        self._lsu = LoadStoreUnit(32, self._mem, self, self._rob) # Load/Store unit

        
        # For iteration
        self._subpipes = tuple(self._eu + [self._bru, self._lsu])

        # Time counter
        self._simtime = 0

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
        self._rob.advstate()
        # Need to increment time
        self._simtime += 1

    def _rob_branch(self, ins):
        """ Clears the pipeline and does the branch (if necessary!). """
        predicted = ins.predicted
        cond = ins.robbr[0]
        
        # Need to tell decoder that the branch has been resolved, so blocking can stop
        self._decoder.branchResolved(ins, cond)
        self._fetcher.branchResolved()

        if cond and not predicted:
            #self._rs.pipelineClear() # I dont think I actually needed this, but...
            print 'BRANCHY TO',ins.robbr
            self._fetcher.update(0, ins.robbr[1])
            self._decoder.pipelineClear()
            self._rs.pipelineClear()
            self._reg.resetScoreboard()
            return True # return true if rob needs to clear speculative instructions
        elif not cond and predicted:
            print 'NOT BRANCHY',ins.asrc
            self._fetcher.update(0, ins.asrc + 1)
            self._decoder.pipelineClear()
            self._rs.pipelineClear()
            self._reg.resetScoreboard()
            return True # return true if rob needs to clear speculative instructions
        else:
            print 'Good BRANCHY!'
        return False

    def _rob_branch_poisoned(self, psnd):
        """ Stop early pipeline input stages from blocking on discarded branches. """
        self._decoder.branchResolved(None, False)
        self._fetcher.branchResolved()

    # EASIER TO SORT OUT BRANCHES IF THEY ARE DEALT WITH IN COMMIT    
    def _branch(self, cond, pred, dest, ins):
        """ Clears the pipeline and does the branch (if necessary!). """
        ins.robbr = (cond, dest) # Jam stuff in here so rob can do things later

    def _usePrediction(self, pred, branch):
        """ Uses the prediction to set the fetch target prematurely. Must run after fetch has set decoder input. """
        if pred:
            print "* Predictor (in decode stage) decided branch {0:s} will be taken.".format(str(branch))
            dest = branch.getOpr()[-1] # TODO: Pass in?
            print ' PREDICTED A JUMP TO',dest,branch
            # Set the new dest
            self._fetcher.update(0, dest)
            self._fetcher._state[0] = dest
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
        print "Program has halted the simulation! Doing final update and print."
        self._update()

        print self._reg
        # self.displayState() # Prints too much!

        print '\n=== Simulation Stats ===\n'
        total_exec = self._rob.INSTRUCTIONS_COMMITTED + self._rob.INSTRUCTIONS_DISCARDED
        print 'CYCLE COUNT:', self._simtime
        print 'INSTRUCTIONS EXECUTED:', total_exec
        print 'AVG INSTRUCTIONS PER CYCLE:', float(total_exec) / float(self._simtime)
        print 'INSTRUCTIONS COMMITTED:', self._rob.INSTRUCTIONS_COMMITTED
        print 'INSTRUCTIONS DISCARDED:', self._rob.INSTRUCTIONS_DISCARDED
        print 'TOTAL BRANCHES:', self._rob.TOTAL_BRANCHES
        print 'BRANCH MISPREDICTIONS:', self._rob.BRANCH_MISPREDICTIONS

        if check_file:
            print "\nRunning check."
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
        print 'lolwut fetchins',type(toDecodeList),toDecodeList,type(pc),pc
        for i,toDecode in enumerate(toDecodeList):
            print '* Fetch stage loaded from mem, passing ({0:d}): {1:08d} to decode stage.'.format(pc+i, toDecode)

        # Get issued instructions from decoder.
#        issuedALU, issuedBRU, issuedLSU, stallingDEC = self._decoder.issue()
        issued, stallingDEC = self._decoder.issue()

        if stallingDEC != -100:
            self._fetcher.inc(len(issued))
            # Pass fetched to decode
            self._decoder.queueInstructions(toDecodeList, range(len(toDecodeList)) + pc)


        dispatchedALU, dispatchedBRU, dispatchedLSU = self._rs.dispatch()

        
#        print '* Decode stage determined the instruction is {0:s}, reading any input registers and passing to execution unit'.format(str(toExecuteA))

        # Issue instructions to execute units #TODO: Targeted EUs (e.g. ALU, branch, Mem)
        shuffle(dispatchedALU) # Shuffle to flag up bugs!
        #stallingALU = False
        lostinsALU = []
        for i,(eu,ins) in enumerate(izip_longest([eu for eu in self._eu if not eu.willStall()], dispatchedALU, fillvalue=Instruction.NOP())):
            print 'EU', i, ins
            stallingALU = eu.execute(ins)
            if stallingALU:
                lostinsALU.append(ins)

        if not dispatchedLSU:
            dispatchedLSU = [Instruction.NOP()]
        for ins in dispatchedLSU:
            print 'LSU', ins
            self._lsu.execute(ins)

        # Need to execute with a nop to actually step the bru pipeline.
        if not dispatchedBRU:
            dispatchedBRU = [Instruction.NOP()]
        for ins in dispatchedBRU:
            print 'BRU', ins
            # Handles printing
            self._bru.execute(ins)


#        if lostinsALU:
            #self._rs.stallingEU('ALU', stallingALU)
            # Stall by putting the instructions back in RS
#            print 'SENDING BACK TO ALU',lostinsALU
#            self._rs.stallingEU(lostinsALU)
#            for ins in lostinsALU:
                # Should not be marked as executing
#                ins.rbstate = 0

        stallingRS = self._rs.queueInstructions(issued) # THIS NEEDS TO GO AFTER DISPATCH AND EUs!
            
        if stallingRS:
            print 'STALLING'
            # Need to stall previous stages
            self._decoder.stall()
            self._fetcher.stall()
            self._rob.decoderStalled(issued) # Need to remove/poison the entries corresponding to stalled
        elif stallingDEC == 1:
            print 'STALLING AT DECODER (half)'
            # Issue has stalled due to a branch before instruction.
            #self._fetcher.stall(1)
            self._fetcher[self._fetcher.BRW_IND] = 1
        elif stallingDEC == 2:
            print 'STALLING AT DECODER (full)'
            # Issue waiting for branch
            #self._fetcher.stall()
            self._fetcher[self._fetcher.BRW_IND] = 1
        elif stallingDEC == 0:
            print 'STALLING AT DECODER (errr..... zero?)' # Probably stupid
            #self._fetcher.stall(2)
            self._fetcher[self._fetcher.BRW_IND] = 1
        
        # Commit results from reorder buffer
        self._rob.commit()
            
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
        print '\n',self._rob,'\n'
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
            try:
                args = usr.split(' ')[1:]
                cpu.dump(int(args[0], 0), int(args[1], 0))
            except:
                print 'Invalid range.'
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
            try:
                arg = usr.split(' ', 1)[1]
                print eval(arg, globals(), locals())
            except Exception as e:
                print e
        elif usr.startswith('p'):
            # Re-print state
            cpu.displayState()
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

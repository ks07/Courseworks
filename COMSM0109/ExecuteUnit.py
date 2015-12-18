#!/usr/bin/env python

from Executor import Executor
from MemoryAccess import MemoryAccess
from Writeback import Writeback

class ExecuteUnit(object):
    """ A general purpose execution unit, with it's own pipeline. """
    
    def __init__(self, myid, mem, cpu, rob):
        """ ID is for debugging and display purposes. """
        self._id = myid;
        self._executor = Executor(cpu) # Requires a reference to cpu, for branches
        self._memaccess = MemoryAccess(mem)
        self._writeback = Writeback(rob)

        # Easy iteration
        self._stages = (self._executor, self._memaccess, self._writeback)

        # Pipeline information (currently for halt)
        self.pipelen = len(self._stages)
        self._stepcount = 0

    def willStall(self):
        """ Returns True if the EU will stall (from multistage ins). """
        return self._executor._ins.cycleLen() > 1 and self._executor._ins.cycleCnt() > 0 # This should really be a method on executor
        
    def execute(self, toExecute):
        """ Runs the current timestep. Should be issued an instruction. """
        # Update the step count (used to tell if pipe is clear of instructions).
        if toExecute.getOpc() == 'nop' or toExecute.getOpc() == 'dnop':
            self._stepcount += 1
        else:
            self._stepcount = 0
        # Pass to execute
        self._executor.updateInstruction(toExecute)

        # Execute Stage (this might undo all the previous steps, if we branch!)
        toMacc, stalled = self._executor.execute()
        # Handles printing

        # Pass to memory access
        self._memaccess.updateInstruction(toMacc)

        # Memory access stage
        toWriteback = self._memaccess.memaccess()

        # Pass to writeback
        self._writeback.updateInstruction(toWriteback)

        # Writeback stage
        self._writeback.writeback()

        return stalled

    def advstate(self):
        """ Updates the state of all components, ready for the next iteration. """
        for stg in self._stages:
            stg.advstate()

    def __str__(self):
        return '\n--Execution Unit {0:d}--\n{1:s}'.format(self._id, '\n'.join((str(stg) for stg in self._stages)))

    # For list printing
    def __repr__(self):
        return str(self)
    
    def invalidateExecute(self):
        self._executor.invalidateInstruction()

    def hasInstructions(self):
        """ Tells if this unit has any instructions waiting to complete. (For halt) """
        return self._stepcount < self.pipelen
